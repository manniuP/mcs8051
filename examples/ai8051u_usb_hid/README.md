# ai8051u_usb_hid —— STC USB-HID（Keil C251）移植到 SDCC mcs251（持续上报版）

把 STC 官方 **Ai8051U-32Bit/42 USB-HID** 例程（来源：`AI8051U-DEMO-CODE-V1.2.zip`）
从 Keil C251 移植到 SDCC mcs251，并按“**板上无按键**”改为**持续上报**。

## 目录

| 路径 | 说明 |
| --- | --- |
| `src/` | 翻译后的 SDCC 源码；`usb_hid_all.c` 为**单编译单元**（main + 全部 ISR） |
| `hidread.ps1` | 主机端 HID 读取器（P/Invoke `hid.dll`，读 64 字节输入报告） |
| `usb_hid.ihx` | 固件（`xmake build usbhid`） |

## 移植要点（同 docs/14）

- `tools/keil2sdcc_c.py` 翻译 Keil C251 源码；USB SFR 用 `lib/include/ai8051u_sfr.h`。
- **坑一**：单编译单元 `usb_hid_all.c`，否则 SDCC 不生成含 `_usb_isr` 的 IVT。
- **坑二**：ISR 共享变量 `DeviceState/InEpState/OutEpState` 加 `volatile`。
- `EAXFR` 是**位掩码常量**（`P_SW2.7`），不能写 `EAXFR = 1;`，应为 `P_SW2 |= 0x80;`。

## 与原例程的差异：持续上报

原例程在 `usb_out_ep1()` 里把主机发来的报告原路回显（`usb_out_ep1` → `usb_bulk_intr_in`）。
本板**没有按键**，改为在 `main()` 主循环里，设备配置完成后周期性往 **EP1 IN** 发一帧
64 字节报告（内容 = `n + i`，`n` 递增），供主机持续观察：

```c
if (DeviceState == DEVSTATE_CONFIGURED) {
    IE2 &= ~0x80;                       // 关 USB 中断，避免与 ISR 抢 USBADR
    usb_write_reg(INDEX, 1);
    if (!(usb_read_reg(INCSR1) & INIPRDY)) {
        for (i = 0; i < 64; i++) UsbBuffer[i] = (byte)(n + i);
        usb_bulk_intr_in(UsbBuffer, 64, 1);  // EP1 IN 发一帧
        n++;
    }
    IE2 |= 0x80;
    for (d = 0; d < 20000; d++) { }      // 节流
}
```

## 构建

```powershell
cd <repo>
xmake f --mcs_arch=mcs251
xmake build usbhid            # -> examples\ai8051u_usb_hid\usb_hid.ihx（链到 0xff0000）
```

## 真机验证（AI8051U-34K64）

- 枚举：`USB\VID_34BF&PID_FF01`（HIDClass）——描述符来自 `usb_desc.c`。
- 主机读输入报告（`hidread.ps1`）：

```powershell
powershell -File examples\ai8051u_usb_hid\hidread.ps1 -Vid 0x34BF -ProductId 0xFF01 -Seconds 5
# found HID VID_34BF PID_FF01 ...
#   report#1 len=65 : 00 5f 60 61 62 63 ...
#   report#2 len=65 : 00 60 61 62 ...
#   ...
```

`len=65` = 1 字节 report ID（0）+ 64 字节数据；数据首字节每帧 +1 → **持续上报正常**。
（也可用 STC-ISP 的 HID 收发测试看。）

## 已知限制

- 无按键：只能由设备主动上报；若要“按键触发上报”，需接按键到某 GPIO 并在主循环里扫描。
- 主机读取器仅用于本验证（Windows `hid.dll`）。
