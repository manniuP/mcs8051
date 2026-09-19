# mcs51_c_cobs —— 8 位（mcs51）C 版 COBS 编码自检

用平台无关的 `lib/cobs/cobs.c` 在 **8 位 mcs51** 上做 COBS + 日志帧编码。

## 为什么 C 版能在 8 位跑通

SDCC 的 `--stack-auto` 把局部变量放**栈**上，函数之间不各占一块静态 idata 帧；
而 Zig mcs51 后端目前**每函数一块静态 `_frkN`**，函数一多就爆 256B idata
（8 位 Zig COBS 因此暂时不能链接，见 `docs/交接` §10）。故 8 位用 C 版 COBS。

## 构建

```powershell
cd mcs251
xmake f --mcs_arch=mcs51
xmake build ccobs51      # -> build/examples/at89c52/c_cobs/ccobs51.ihx
```

## 验证（STC15/通用 8051 仿真，无需硬件）

`main.c` 只编码进 `__xdata out[]`、长度写 `__xdata out_len`，然后死循环；
用 WSL 的 ucsim dump XRAM 核对（`sim.cmd` 已放进本目录）：

```bash
ucsim_51 -t STC15 -S in=/dev/null,out=- ccobs51.ihx < sim.cmd
```

预期（frame: id=0x0002, u16=0x1234, XOR=0x02^0x34^0x12=0x24）：

```
_out     @xdata 0x0001:  03 7e 02 04 34 12 24 00      # COBS + 00 定界
_out_len @xdata 0x0041:  08 00                        # = 8（小端）
```

> XOR 校验不含帧首 `0x7E`（主机 `decode.ps1` 从 `Frame[1]` 起算），故为 `0x24`。
