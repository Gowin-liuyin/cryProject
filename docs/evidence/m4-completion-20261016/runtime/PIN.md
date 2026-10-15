# M4 runtime 固定来源

| 项目 | 固定版本与来源身份 | 下载 SHA-256 | 许可证口径 |
|---|---|---|---|
| Binsec | tag `0.11.3`，commit `9749bd8aed7ee0a27959158b1e53e8789cb0e5ab` | `93f6fe439d486b166062ef6dd92c4ce3aa0947b5e18b1c3aa7de2fc3003aa6d9` | 包元数据 `LGPL-2.1-or-later`，原 `LICENSE.md` 保留 |
| opam | `2.6.1`，commit `921b53bf7fca5467b65ccbe714b78618bebd5e97` | `b533d393a6967150d6ef41cb3d71e147e93ecbabeb59e921aa412c0ae79ebe3d` | LGPL-2.1，附原 LICENSE 中的链接例外 |
| Z3 | `z3-4.15.3`，commit `a121e6c6e95c60f50d1561f03762805dabc969e1` | `94549c5e31a75b9c543fe6eea8f32927054765c2e92e696d2d6dde0eedf348a1` | MIT，发行包原 LICENSE 保留 |
| GMP | `6.3.0` 官方源码发行包 | `a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898` | LGPLv3+ 或 GPLv2+，原 COPYING 文件保留 |
| GNU m4 | `1.4.19` 官方源码发行包 | `63aede5c6d33b6d9b13511cd0be2cac046f2e70fd0a07aa9573a04a82783af96` | GPLv3+，原 COPYING 保留 |

官方地址：

- [Binsec release](https://github.com/binsec/binsec/releases/tag/0.11.3)
- [Binsec 固定安装说明](https://github.com/binsec/binsec/blob/9749bd8aed7ee0a27959158b1e53e8789cb0e5ab/INSTALL.md)
- [opam release](https://github.com/ocaml/opam/releases/tag/2.6.1)
- [opam 固定许可证](https://github.com/ocaml/opam/blob/921b53bf7fca5467b65ccbe714b78618bebd5e97/LICENSE)
- [Z3 release](https://github.com/Z3Prover/z3/releases/tag/z3-4.15.3)
- [GMP archive](https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz)
- [GNU m4 archive](https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz)

Binsec/opam/Z3 的摘要来自同时保存的官方 GitHub release API 元数据并在下载后核对；
GMP/m4 为固定官方 HTTPS 下载内容的摘要，不声称已独立验证发行者签名。

`binsec-git-source.sha256` 固定本机 Git checkout 的全部 498 个跟踪文件。
源码 tbz 与 Git 仅有三处发行版本字段替换，见 `release-vs-git.diff` 和对应原字段副本；
没有把源码发行包无条件当作逐字 Git tree。

完整 OCaml/opam 依赖版本与 switch 导出在安装完成后另存；系统 glibc、libstdc++、gcc 等沿用实际 Linux 环境。
Z3 官方 Linux 发行包实际为动态链接 ELF，未宣称完全静态。
