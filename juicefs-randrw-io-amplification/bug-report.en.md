# JuiceFS v1.4.1 random read/write amplification: observations and questions

## 1. What we observed

In a 256 KiB, 50% read / 50% write random-overwrite test on a fixed file set, the application read and wrote about 8 MiB/s each, while JuiceFS issued about 189 MiB/s of GET and PUT each at the object layer. We would like to confirm whether this is related to our usage or configuration, or whether it is the expected behaviour of the current slice compaction strategy under this kind of workload.

The test used JuiceFS v1.4.1, commit `0b90c7db5a929ae6adc5faad948d108efd2c99f9`. Client node1 exposes the file interface through Linux FUSE; node2–node4 run the TiKV metadata engine and the Ceph object store, with 6 Ceph OSDs and an EC 4+2 data pool.

```text
fio → Linux VFS/FUSE → JuiceFS client
                       ├─ TiKV: file attributes and chunk/slice mappings
                       └─ Ceph RADOS: objects holding file content
```

The volume BlockSize is 256 KiB and the client uses `--max-fuse-io 256K`; local data cache and writeback are disabled and `async_dio` is not enabled. Maximum upload/download concurrency is 150/200, buffer 300 MiB, default 2 MiB readahead kept, automatic metadata backup disabled, and normal compaction and deletion enabled. Full parameters and methods are in the [reproduction method](reproduce/README.en.md).

## 2. Two measurement results

### Random read/write: object IO is about 23.7x application IO

We created 128 independent 256 MiB files, 32 GiB in total; each 64 MiB chunk had only one full mapping at the start. The formal run lasted 30 minutes, with 128 jobs each doing 256 KiB random read/write, each job rate-limited to 64 KiB/s per direction, about 8 MiB/s per direction in total.

| Metric | 30-minute test result |
|---|---:|
| Application read / write | 14.0625 GiB each |
| Object GET / PUT | 333.00317 / 332.8125 GiB |
| Object read / write amplification | **23.68023x / 23.66667x** |
| Compaction count and size | 5100 times, 318.75 GiB total, 64 MiB average |
| fio / object request errors | 0 |

Object PUT is exactly `14.0625 GiB foreground writes + 318.75 GiB compaction size`, so about 95.77% of object writes can be explained by compaction size.

### Single file: reads after two small overwrites trigger a full-range compaction

We compared on two independent 64 MiB files. After initialization each file had only one 64 MiB slice mapping; this state was reached naturally during initialization, and no manual compact was issued for these two files.

| Operation | Single overwrite | Two overwrites |
|---|---:|---:|
| Overwrite positions | 16 MiB offset | 16 MiB and 48 MiB offsets |
| Total application overwrite | 256 KiB | 512 KiB |
| Raw mappings / live fragments after overwrite | 2 / 3 | 3 / 5 |
| Subsequent application read | 256 KiB | 256 KiB |
| GET produced by that read and its background work | 256 KiB | **64.5 MiB** |
| PUT produced by that read and its background work | 0 | **64 MiB** |
| Compaction count | 0 | **1** |

Before the read we switched to a new mount process of the same version, so the chunk mapping would not hit the old client's cache. Overwrites, the triggering read and the final full CRC were counted separately. Both CRC checks passed. Of the 64.5 MiB GET in the positive case, 64 MiB corresponds to the compaction range, 256 KiB is the foreground read, and another 256 KiB is not yet broken down by source.

This small case wrote 512 KiB in the overwrite phase and then uploaded 64 MiB, 129x write amplification in total; it illustrates the trigger mechanism and does not replace the ~23.7x measured on the 128-file random workload. Full data is in the [test report](test-report.en.md).

## 3. Our understanding of the cause

A chunk's current file content can be composed of several slice mappings. A small overwrite keeps the uncovered parts of old slices and adds a new slice. In the upstream code, a write invalidates that chunk's mapping cache; a later read that misses the cache builds the live fragments. When the raw record count or the live fragment count reaches 5, the read path may request compaction asynchronously. [Read/Write implementation](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/meta/base.go#L2081)

In the minimal case the live content is, in order, "head of old data, new data B, middle of old data, new data C, tail of old data" — exactly 5 fragments. The compaction range still covers the whole 64 MiB; an object BlockSize of 256 KiB does not mean compaction touches only 256 KiB. Compaction reads the current live content, creates a new slice and re-uploads the corresponding objects, then replaces the metadata mapping. [Compaction range computation](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/meta/slice.go#L157), [actual data compaction](https://github.com/juicedata/juicefs/blob/0b90c7db5a929ae6adc5faad948d108efd2c99f9/pkg/vfs/compact.go#L54)

We therefore understand the main cost as repeatedly reading and rewriting a large range of live data. Not every 256 KiB write immediately rewrites 64 MiB; the exact frequency also depends on read timing, cache hits and compaction concurrency control. The fio rate limit constrains application requests, not these internal compaction object IOs.

## 4. What we would like the community to confirm

1. **Is our understanding of the cause accurate?** After a few overwrites create 5 live fragments, does a read triggering compaction of the whole 64 MiB range fall within the current design's intended trade-off between read performance and compaction cost? Is our trigger chain and byte accounting accurate?
2. **Can usage improve it?** For workloads of small-block random overwrites interleaved with reads, is our configuration or data organization unsuitable? Are there recommended parameters, caching strategies or usage patterns that can reduce object IO amplification without changing the source?
