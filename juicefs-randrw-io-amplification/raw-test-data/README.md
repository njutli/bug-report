# 原始数据

[English](README.en.md)

这些记录对应测试报告中的两组实验，均使用JuiceFS v1.4.1。

| 目录 | 对应内容 |
|---|---|
| [upstream-independent](upstream-independent/) | 30分钟随机读写的完整fio命令、输出、IO统计数据采样和最终CRC |
| [mini-negative](mini-negative/) | 单文件一处覆盖的初始化、覆盖写、读取、CRC及slice映射 |
| [mini-positive](mini-positive/) | 单文件两处覆盖的相同步骤及记录 |

`fio.json`为fio直接输出；`argv.json`和 `exit.json`记录实际命令与退出结果。`metrics-boundaries.jsonl`从测试期间的IO统计数据采样中选取起止点，保留原始行，其中 `text` 为该次JuiceFS统计接口返回的完整文本。`*-mapping.json`和元数据摘要由测试程序从JuiceFS metadata dump中提取。

[source-manifest.json](../source-manifest.json)记录文件来源和SHA256。原始记录保留执行时的时间、路径及进程信息。

[results.json](../results.json)是根据原始数据计算的汇总。以下命令只读解析本地文件，先验证文件哈希，再复算fio与FUSE字节、GET／PUT、合并量和放大率：

```sh
python3 tools/recompute.py
```

初始化、人工合并及CRC不计入正式放大率。最小复现的覆盖写和触发读取使用不同挂载进程，分别在各自进程内计算增量。
