# ai8051u_mdu —— MDU（32 位硬件乘除单元）真机验证

用 `lib/mdu/mdu.c`（头 `lib/include/ai8051u_mdu.h`）调用 AI8051U 的 **MDU**（手册 §36），
算几组已知结果经 **UART1(P3.1, 115200 8N1)** 周期打印。

## 构建 / 烧录

```powershell
cd mcs251
xmake f --mcs_arch=mcs251
xmake build mdu          # -> examples/ai8051u_mdu/mdu.ihx
```
烧录（AiCube，芯片选 **AI8051U-34K64**，CPU 指令模式 32-Bit）；串口 115200 读 P3.1。

## 真机结果（2026-09-16，AI8051U-34K64 通过）

```
MDU mul=2468ACF0 div=05555555 mod=00000001 sq=00FFE001
```
预期：`0x12345678*2=0x2468ACF0`、`0x10000000/3=0x05555555`(余 1)、`4095*4095=0x00FFE001`，均一致。

## 为什么这么实现（关键坑）

**不能用普通 C 直接给 R0-R7 赋值**：SDCC 的寄存器分配会用 R5-R7 暂存第二个操作数，
把 MDU 的第一个操作数（R4-R7）覆写（本会话实测踩过，结果错）。故 `mdu.c` 的做法是：
1. C 把两个 32 位操作数（**大端**）写进 data 暂存 `mdu_s[8]`；
2. 一段**不透明 `__asm`** 把暂存搬进 R4-R7/R0-R3 → `mov DMAIR,#op` 触发 → 结果写回 `mdu_s`；
3. C 从 `mdu_s` 组装返回。

MDU 规格：`DMAIR`@0xED（**必须立即数写**）；arg1=R4-R7、arg2=R0-R3（大端）；
`0x02`=32 位乘(3clk)、`0x04`=32 位无符号除(19clk；商 R4-R7、余数 R0-R3；除零→0xFFFFFFFF)。
有符号除指令码见手册 §36.3.3（暂未实现）。**仿真不建模 MDU → 只能真机验证。**
