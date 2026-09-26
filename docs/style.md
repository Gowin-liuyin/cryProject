# 自有代码风格

本约定适用于 src/、include/、tests/ 的自有 C 代码，以及 CMake 和必要脚本。
vendor/ 保留上游原始内容；tests/vectors/ 和 docs/evidence/ 保留原始数据。
缺陷补丁中的自有函数遵守同一 C 风格，但不对整份上游文件批量重排。

## C11

- 4 空格缩进，不用制表符；通常最多 100 列，工具按 .clang-format 换行。
- 函数左大括号另起一行；控制语句左大括号跟随条件；所有分支和循环都写大括号。
- 一条声明只声明一个变量；语句不挤在一行；声明靠近用途，保留必要的局部作用域。
- 函数、参数、变量和字段使用描述性的 snake_case；宏使用 UPPER_SNAKE_CASE。
- 长度、容量、索引和时间说明对象及单位；条件变量用 has_/is_ 等表达判断含义。
- 本地头文件与标准库头文件分组；头文件分开组织 guard、include、常量、类型及接口。
- 注释用简短中文解释原因、约束和实验边界，不逐行翻译代码。
- 公开错误在调用内核前检查；已获取的资源在退出前释放；内部密码验证结果不成为 CLI 状态。
- 测试可在首次失败时结束进程，但文件校验程序必须拒绝截断、额外字段和非法数字。

固定使用 clang-format 21（包括 Apple clang-format 21），避免版本差异反复改写格式。
正常构建不依赖格式工具；本机已安装工具时运行：

```sh
cmake --build --preset baseline --target format-check
cmake --build --preset baseline --target format
```

format 仅修改自有 .c/.h，之后必须检查 diff；format-check 不写文件。
工具不在 PATH 时可用 `-DCLANG_FORMAT_EXECUTABLE=/absolute/path/to/clang-format` 指定；
macOS 会尝试 Xcode 的 clang-format。格式化不替代功能或内存检查。

## 构建与脚本

CMake 使用小写命令、明确的变量、4 空格和 .cmake-format.json 的换行规则；
较长的构建元数据放在 cmake/build_configuration.txt.in，而不夹在构建逻辑中。
CMake 格式检查使用固定版本的开发工具，不是应用运行依赖：

```sh
uvx --from cmakelang==0.6.13 cmake-format --check CMakeLists.txt cmake/*.cmake
```

Shell 使用 POSIX sh、4 空格、引用路径变量、分行条件分支和明确的失败退出；
Makefile 的命令缩进使用 Tab。JSON 使用 2 空格，统一由 .editorconfig 约定。
元数据模板中的原样字符串、测试长字符串和机器生成证据不强行截断。
