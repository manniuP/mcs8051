# ai8051u_usb_cdc —— STC USB-CDC（Keil C251）移植到 SDCC mcs251

把 STC 官方 **Ai8051U-32Bit/43 USB-CDC** 例程（来源：`AI8051U-DEMO-CODE-V1.2.zip`）
从 **Keil C251** 移植到本仓库的 **SDCC mcs251** 工具链，用于打通 STC 只提供 Keil `.LIB`
的那些库（USB 协议栈）。

## 目录

| 路径 | 说明 |
| --- | --- |
| `src/` | **已翻译**为 SDCC 的 C 源码（16 个 `.c/.h`） |
| `usb_cdc_sdcc.lib` | 由 `sdar` 打包的 SDCC 库（USB 协议栈对象，对应 Keil 的 `usb_cdc_32.LIB`） |
| `usb_cdc.ihx` | 全量链接产物（`xmake build usbcdc`） |

## 翻译做了什么

用 `tools/keil2sdcc_c.py` 处理 Keil C251 源码 + 少量手工替换：

- `#include "../comm/AI8051U.h"` → `#include "ai8051u_sfr.h"`（仓库统一的 SDCC SFR 头）
- `#include <intrins.h>` → `#include "mcs_intrins.h"`
- `bit` → `__bit`、`xdata` → `__xdata`、`code` → `__code`、`interrupt N` → `__interrupt(N)`、
  `sfr/sbit` → `__sfr/__sbit __at(...)`（脚本内置规则）

USB 所需的 SFR（`USBCLK/USBDAT/USBADR/*IF/*IE` 等）已在 `lib/include/ai8051u_sfr.h` 中。

## 构建

```powershell
cd <repo>
xmake f --mcs_arch=mcs251
xmake build usbcdc            # -> examples\ai8051u_usb_cdc\usb_cdc.ihx（链到 0xff0000）
```

打成 SDCC 库（应用只需提供 `main.c` + `uart.c`，用 `-l usb_cdc_sdcc` 链接协议栈）：

```powershell
$bin = tools\sdcc-mcs251-windows-x64\sdcc-mcs251\bin
& $bin\sdar.exe -rc examples\ai8051u_usb_cdc\usb_cdc_sdcc.lib `
    examples\ai8051u_usb_cdc\src\usb.rel examples\ai8051u_usb_cdc\src\usb_desc.rel `
    examples\ai8051u_usb_cdc\src\usb_req_std.rel examples\ai8051u_usb_cdc\src\usb_req_class.rel `
    examples\ai8051u_usb_cdc\src\usb_req_vendor.rel examples\ai8051u_usb_cdc\src\util.rel
& $bin\sdranlib.exe examples\ai8051u_usb_cdc\usb_cdc_sdcc.lib
# 应用链接：sdcc -mmcs251 --model-large --code-loc 0xff0000 main.rel uart.rel usb_cdc_sdcc.lib -o app.ihx
```

## 关键坑：SDCC mcs251 的中断向量表只在 main 模块生成

`SDCCglue.c` 的 `createInterruptVect` 只在**定义了 `main` 的那个模块**里生成 IVT，
且只收该模块里的 `__interrupt` 函数。本工程原先把 ISR 放在 `usb.c`/`uart.c`，
与 `main.c` 不同模块 → 编译出的 IVT 里**没有** `ejmp _usb_isr`/`_uart2_isr`，中断不会触发。

修复：用 **单编译单元** `src/usb_cdc_all.c` 把 main + 全部 `.c` 一起包含，一次编译，
SDCC 就会生成完整 IVT（`vector 8 @0xFF0043 → ejmp _uart2_isr`、
`vector 25 @0xFF00CB → ejmp _usb_isr`，HOME 217 字节、CSEG 顺延到 0xFF0165）。

> 因此**不要**再单独编译 `usb.c`/`uart.c`…（会与 `usb_cdc_all.c` 符号重复）。

## 关键坑 2：ISR 与主循环共享的变量必须 `volatile`

SDCC 会把普通全局缓存/优化，主循环读不到 ISR 更新的值（Keil 不敏感）。表现为：
USB **能枚举**（EP0 控制走 ISR 正常），但 **EP1 块数据不通**（`uart_polling` 读不到
`RxRptr/RxWptr`、`UsbInBusy` 等的变化）。给 `DeviceState / RxRptr / RxWptr / TxRptr /
TxWptr / InEpState / OutEpState / UsbInBusy / UsbOutBusy / UartBusy` 加 `volatile` 后即通。

## 状态 / 验证

- ✅ 8 个 `.c` 用 SDCC mcs251 编译、链接通过（`HOME=0xFF0000`，代码约 9K，IVT 正确）。
- ✅ SDCC `.lib` 打包成功，应用可链接。
- ✅ **真机回环通过**（AI8051U-34K64）：
  - 设备枚举为 CDC：`VID_34BF&PID_FF02`，`BusReportedDeviceDesc = "AIC USB Serial"`，COM10 = `USBSER000`；
  - P4.2↔P4.3 跳线，PC 经 COM10 发 `LOOP0..LOOP4\r\n`，**原样回显**（USB→P4.3→跳线→P4.2→USB）。
- 对照：STC 官方 Keil `usb_ser.hex` 同板同跳线也回环 → 硬件/接线无误；差异在 SDCC 移植（即上述两个坑）。
- 其他改动：`config.h` FOSC 改 40MHz（本板 IRC；UART2 的 `BR()` 才准）；P4.3(TXD2) 设推挽。
- 说明：例程原为 Keil “XSmall” 内存模型（默认 edata）；本移植用 SDCC `--model-large`（全局进 xdata）。

## 已知限制（本工具链）

- 纯 Zig 后端不支持结构体字段访问，但 **USB 协议栈是 C**，由 SDCC 编译，不受影响。
- 其他 STC Keil 库（MDU32/TFPU/FPMU 等）只有 `.LIB`、无源码，暂不能这样移植（DSP32 有 `.ASM` 源）。
