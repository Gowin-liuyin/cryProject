## 5. 逐数据集明细（机器生成，未手抄）

**RTLF α=0.01，二值结论，族外，不进 Holm；最大 t 不适用。**

四类计数：`no_difference_detected` = 30，`difference_detected` = 12，`blocked` = 0（其中 `blocked_upstream_zero_filter` = 0），`failed` = 0。

`difference_detected`（exit 11）的数据集：m2-m2-s1-unfixed-main m2-m2-s1-fixed-main m2-m2-s2-unfixed-main m2-m2-s2-fixed-main m2-m2-s3-unfixed-main m2-m2-s3-fixed-main m4-m4-s1-vuln-main m4-m4-s2-vuln-main m4-m4-s3-vuln-main m4-m4-c1-vuln-control m4-m4-c2-vuln-control m4-m4-c3-vuln-control 

| 数据集 | n_X | n_Y | exit_code | status | 含 0 值 |
| --- | --- | --- | --- | --- | --- |
| m2-m2-s1-unfixed-main | 10000 | 10000 | 11 | difference_detected | no |
| m2-m2-s1-unfixed-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m2-m2-s1-fixed-main | 10000 | 10000 | 11 | difference_detected | no |
| m2-m2-s1-fixed-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m2-m2-s2-unfixed-main | 10000 | 10000 | 11 | difference_detected | no |
| m2-m2-s2-unfixed-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m2-m2-s2-fixed-main | 10000 | 10000 | 11 | difference_detected | no |
| m2-m2-s2-fixed-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m2-m2-s3-unfixed-main | 10000 | 10000 | 11 | difference_detected | no |
| m2-m2-s3-unfixed-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m2-m2-s3-fixed-main | 10000 | 10000 | 11 | difference_detected | no |
| m2-m2-s3-fixed-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m5-m5-s1-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m5-m5-s1-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m5-m5-s2-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m5-m5-s2-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m5-m5-s3-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m5-m5-s3-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s1-on-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s1-on-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s1-off-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s1-off-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s2-on-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s2-on-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s2-off-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s2-off-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s3-on-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s3-on-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s3-off-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m3-m3-s3-off-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m4-m4-s1-vuln-main | 10000 | 10000 | 11 | difference_detected | no |
| m4-m4-s1-ct-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m4-m4-s2-vuln-main | 10000 | 10000 | 11 | difference_detected | no |
| m4-m4-s2-ct-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m4-m4-s3-vuln-main | 10000 | 10000 | 11 | difference_detected | no |
| m4-m4-s3-ct-main | 10000 | 10000 | 10 | no_difference_detected | no |
| m4-m4-c1-vuln-control | 10000 | 10000 | 11 | difference_detected | no |
| m4-m4-c1-ct-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m4-m4-c2-vuln-control | 10000 | 10000 | 11 | difference_detected | no |
| m4-m4-c2-ct-control | 10000 | 10000 | 10 | no_difference_detected | no |
| m4-m4-c3-vuln-control | 10000 | 10000 | 11 | difference_detected | no |
| m4-m4-c3-ct-control | 10000 | 10000 | 10 | no_difference_detected | no |

### 5.1 机器核对记录

- 每个数据集目录 `<数据集>/` 含 `normalized.csv`、`rtlf.json`、`rtlf.log`、`exit_code.txt`、`input.sha256`；`results/<数据集>/` 是同一批远端原件的镜像，两组文件逐字节相同。
- `exit_code.txt` 与 `rtlf.json` 的 `metadata.exit_code`：42/42 一致；42/42 的 JSON 可被 `jsonlite::fromJSON` 解析。
- RTLF 自报 `statistics.series_x/y.count` 与输入 `n_X`/`n_Y`：42/42 一致（不一致 0 项），说明工具内部的零值过滤未丢弃任何样本。
- 固定种子确定性：同一输入按同参数复跑一次，除 `metadata.timestamp` 外逐字节相同（`logs/determinism-check/`）。
- 42/42 的 `rtlf.log` 为 0 字节：`-q` 模式下结论只写入 `rtlf.json` 与退出码，属预期行为。
- 输入来源：`docs/evidence/platform-collection-20261016/stats/<数据集>/normalized.csv.gz` 解压（`V1,V2` 表头 + 原行序 `X,<ns>` / `Y,<ns>`），与本地 `awk` 独立复算 42/42 逐字节一致；源 CSV 解压 sha256 与电池记录的 `input.sha256` 42/42 一致（`logs/local-staging-meta.tsv`）。
- 本表数字全部来自远端退出码与 `rtlf.json`；远端工作根 `/home/nss-marker/yhr/Cry/platform-rtlf-20261016/`。
