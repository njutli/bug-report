# Raw data

These records correspond to the two experiments in the test report, all using JuiceFS v1.4.1.

| Directory | Contents |
|---|---|
| [upstream-independent](upstream-independent/) | Complete fio command, output, IO counter samples and final CRC for the 30-minute random read/write |
| [mini-negative](mini-negative/) | Initialization, overwrite, read, CRC and slice mappings for the single-file single-overwrite case |
| [mini-positive](mini-positive/) | The same steps and records for the single-file two-overwrite case |

`fio.json` is direct fio output; `argv.json` and `exit.json` record the actual command and exit result. `metrics-boundaries.jsonl` selects the start and end points from the IO counter samples during the test and keeps the original lines, where `text` is the full text returned by that JuiceFS statistics query. `*-mapping.json` and the metadata summaries are extracted by the test program from the JuiceFS metadata dump.

[source-manifest.json](../source-manifest.json) records file origins and SHA256. The raw records keep the time, path and process information at execution time.

[results.json](../results.json) is the summary computed from the raw data. The following command only parses local files read-only: it first verifies the file hashes, then recomputes the fio and FUSE bytes, GET/PUT, compaction size and amplification:

```sh
python3 tools/recompute.py
```

Initialization, manual compaction and CRC are not counted in the formal amplification. The minimal reproduction uses different mount processes for the overwrite and the trigger read, and computes the increment within each process separately.
