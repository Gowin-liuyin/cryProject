attempt: tar --exclude=platform-mona2-20261016-1256c4cca76d/originals.tar.gz -czf platform-mona2-20261016-1256c4cca76d/originals.tar.gz platform-mona2-20261016-1256c4cca76d
result: exit 1, stderr: tar: platform-mona2-20261016-1256c4cca76d: 在我们读入文件时文件发生了变化
cause: 打包目标写在被归档目录内，父目录 mtime 在被读取时变化
handling: 保留部分产物于本目录，改在根外生成后再移入
time: 2026-10-16T02:10:32+08:00
followup: 首次清单把 ORIGINAL_SHA256SUMS 自身也列入（重定向先建空文件，find 随后看到它），
该行校验必然失败。已改为排除清单文件自身与 originals.tar.gz（后者摘要另存 originals.tar.gz.sha256）
后重新生成清单，并在根外重建压缩包后移入。
