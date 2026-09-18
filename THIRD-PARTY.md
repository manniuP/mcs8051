# 第三方内容与许可声明（THIRD-PARTY）

本仓库整体以 **Apache License 2.0** 发布（见 [`LICENSE`](LICENSE)）。
**下列第三方内容不适用 Apache-2.0**，其版权归各自权利人，按各自条款使用/分发。
若权利人认为此处使用不当，请告知，我们会删除相应内容。

## STC（STC Micro / 深圳国芯，www.STCAI.com）

以下文件为 STC 官方 SDK / 头文件的**原样，或翻译 / 自动生成的衍生**：

| 路径 | 来源 | 性质 |
| --- | --- | --- |
| `lib/stc-hal/` | STC 官方 AI8051U 外设库（AiCube / 官网 SDK） | 原样保留，文件头含 `Web: www.STCAI.com` |
| `examples/ai8051u_usb_cdc/src/` | STC 官方 `AI8051U-DEMO-CODE-V1.2` 的 USB-CDC 例程（Keil C251） | 由 `tools/keil2sdcc_c.py` 翻译为本工具链可编译的 SDCC C，属衍生作品 |
| `examples/ai8051u_usb_hid/src/` | 同上，HID 例程 | 同上 |
| `lib/include/ai8051u_sfr.h` | STC 官方 Keil 头 `AI8051U.keil.h` | 由 `tools/keil2sdcc.py` 自动生成 |
| `docs/21-指令周期参考与bench验证.md`、`tools/mcs_cycles.py` | STC 官方 `AI8051U` 手册 附录A.1.3 指令表 | 指令周期**数据**的摘录/整理（事实性数据，注明出处） |

> 版权归 STC；此处仅用于 STC 芯片的兼容 / 移植。再分发请保留 STC 原始声明并遵守 STC 的条款。
> 本仓**未分发**的 STC 资料（Keil 头 / SDK 原件等）放在 `.gitignore` 排除的 `tools/vendor/`，
> 需自行从 STC 官网获取。

## Keil / Arm

- `lib/include/mcs_intrins.h`：对 Keil `<intrins.h>` **语义的独立重写**（不含 Keil 代码）。
- `lib/stc-hal/Type_def.h` 等 STC 头中的 Keil 类型别名随 STC 内容一并声明（见上）。

## SDCC

- 本仓**未复制** SDCC 源码；`lib/crt0/*.asm` 系参考 SDCC 文档（`sdcc-c251/doc/mcs251/abi.md`）
  自行编写。
- SDCC 及其 MCS-251 分支为 **GPL**，见独立仓 `manniuP/sdcc-c251`。

## 其它

- `compiler/`（Zig + MCS 后端）：源自 Zig 项目，**MIT**；发布仓 `manniuP/mcs8051` 中以子模块
  `manniuP/zig-mcs51-backend` 引入。
- `lib/cobs/`、`lib/cordic/`、`lib/uart251/`、`lib/mdu/`、`lib/include/c51.h`、
  `devices/`（型号/存储/SFR 矩阵数据）等为本项目原创。
