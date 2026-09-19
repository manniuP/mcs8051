# ai8051u_usb_cdc_cobs —— COBS 日志帧走 USB-CDC

把 `lib/cobs` 的轻量日志帧**直接从 USB-CDC（虚拟串口）输出**，摆脱 UART 线；
主机用 `examples/ai8051u/zig_log/decode.py`（或等价的 `decode.ps1`）解码（帧格式相同）。

## 构建 / 状态

```powershell
cd mcs251
xmake f --mcs_arch=mcs251
xmake build usbcdcobs        # -> build/examples/ai8051u/usb_cdc_cobs/usb_cdc_cobs.ihx
```

- **状态：编译/链接通过 + 真机通过**（CSEG ≈16.4KB，XSEG 820 B，< 64KB）。
- **真机结果（AI8051U-34K64，2026-09-16）**：烧录后板子 USB 枚举为
  `VID_34BF&PID_FF02`（`AIC USB Serial`）→ COM 口；主机解码
  **`frames ok=222 bad=0`**，`count` 从 14 递变到 124、每帧后跟 `msg "hello"`。
- **复现**（关掉 AiCube 释放 CDC 口后）：
  ```powershell
  python ..\ai8051u_zig_log\decode.py -p COM10 -s 5
  # 或（PS 版）：powershell -File ..\ai8051u_zig_log\decode.ps1 -Port COM10
  ```

## 实现要点

- `usb_cdc_cobs_all.c`：**单编译单元**，`#include` 复用 `../usb_cdc/src/` 的全部
  驱动源码（`uart.c`/`usb.c`/…，含中断），因为 SDCC mcs251 **只在含 `main` 的模块**生成
  中断向量表（见 `docs/14-USB-CDC移植笔记.md`）。
- `main` 周期用 `cobs_init/cobs_log_begin/cobs_log_u16/cobs_log_str/cobs_log_end` 编帧，
  再 `cdc_send()` 把字节塞进 CDC 发送环形缓冲 `TxBuffer`；`uart_polling()` 负责送 EP1 IN。
- 每次发两帧：`0x0002 count`（递变）与 `0x0005 msg "hello"`。

## 已知坑（沿用 usb_cdc）

- 中断向量表只在含 `main` 的模块生成 → 必须单编译单元。
- ISR 与主循环共享变量要 `volatile`。
- `EAXFR` 是位掩码常量：`P_SW2 |= 0x80;`（不能写 `EAXFR = 1;`）。
- `usb_init` 用内部 IRC48M，与系统 FOSC 无关。
