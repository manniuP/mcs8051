# examples 目录

按**芯片/平台**分组（各工程说明与构建目标见 [`docs/09-工程与示例总览.md`](../docs/09-工程与示例总览.md)）：

| 目录 | 平台 | 构建 |
| --- | --- | --- |
| `ai8051u/` | AI8051U（MCS-251 32 位；部分支持 8 位模式） | `xmake f --mcs_arch=mcs251` |
| `at89c52/` | AT89C52 / 通用 8 位 MCS-51（ucsim 仿真，无需硬件） | `xmake f --mcs_arch=mcs51` |
| `portable/` | 便携工具链打包模板（`tools/make_portable.ps1` 用） | — |
| `vscode_c_cmake/`、`vscode_mixed_xmake_zig/` | VS Code 集成示例 | 见各自目录 |

构建流程见 [`docs/02-工程结构与构建流程.md`](../docs/02-工程结构与构建流程.md)；
SFR 用法（`dev.sfr` / `dev.reg` / `dev.p`）见 [`docs/23-寄存器操作与SFR可读API.md`](../docs/23-寄存器操作与SFR可读API.md)。

> **构建产物**统一输出到仓库根 `build/examples/<平台>/<名>/`（如
> `build/examples/ai8051u/zig_led/led.ihx`）；本目录只放源码，`.gitignore` 只需忽略 `build/`。
