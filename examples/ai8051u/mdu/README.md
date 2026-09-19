# ai8051u_mdu —— MDU（32 位硬件乘除单元）真机验证

用 `lib/mdu/mdu.c`（头 `lib/include/ai8051u_mdu.h`）调用 AI8051U 的 **MDU**（手册 §36），
算几组已知结果经 **UART1(P3.1, 115200 8N1)** 周期打印。

## 构建 / 烧录

```powershell
cd mcs251
xmake f --mcs_arch=mcs251
xmake build mdu          # -> build/examples/ai8051u/mdu/mdu.ihx
```
烧录（AiCube，芯片选 **AI8051U-34K64**，CPU 指令模式 32-Bit）；串口 115200 读 P3.1。

## 真机结果（2026-09-16，AI8051U-34K64 通过）

```
MDU mul=2468ACF0 div=05555555 mod=00000001 sq=00FFE001
```
预期：`0x12345678*2=0x2468ACF0`、`0x10000000/3=0x05555555`(余 1)、`4095*4095=0x00FFE001`，均一致。

## 运行期自校验版（`main.c`）——**真机通过（2026-09-16）**

为避免「常量参数被编译器在编译期算掉、MDU 没真跑」，`main.c` 改为：
- 操作数放 `volatile` 且随循环递变（运行期，无法折叠）；
- 无符号：对每组用 MDU 算 `p=mul、q=div、r=mod`，回验 `mul(div(a,b),b)+mod(a,b)==a`；
- 有符号：与 C 的 `/`、`%`（SDCC 软件参考）逐组比对。

真机输出（AI8051U-34K64，115200）：

```
BOOT!!! AI8051U MDU
alive
MDU runtime test
i=00 p=02040608 q=00810182 r=00000000 PASS
...
i=07 p=3C454E53 q=0D62D4B8 r=00000003 PASS
pass=08 fail=00
mul=2468ACF0 div=05555555 mod=00000001 sq=00FFE001
s00 q=05555555 r=00000001 PASS
...
s05 q=FAAAFB0A r=FFFFFFFF PASS
signed pass=06 fail=00
```
即：无符号 8/8、有符号 6/6 全通过。

另外做**随机向量对拍**：`xorshift32` 运行期生成 8 组 `a/b`（`b` 非 0），
把 MDU 的 mul/div32u/mod32u/div32s 与 C 的 `*`、`/`、`%`（SDCC 软件参考）逐组比对，
结果与运行期值相关、编译器无法预计算。

**真机实测**：心跳每行都做一次随机对拍，持续输出 `HB nn ok`（未见 FAIL），例如
`HB 002F ok … HB 0035 ok`（受 C 软件参考 32 位乘除较慢影响，约 0.86s/轮）。

之后进入**主循环心跳**：每 500ms 翻转 P1.1（指示灯）并打印 `HB n ok`，
每轮用运行期值再跑一遍 `mul/div/mod` 互验 —— **跑飞/卡死时心跳与 HB 输出会停**，
据此判断程序是否还在正常跑。

## 为什么这么实现（关键坑）

**不能用普通 C 直接给 R0-R7 赋值**：SDCC 的寄存器分配会用 R5-R7 暂存第二个操作数，
把 MDU 的第一个操作数（R4-R7）覆写（本会话实测踩过，结果错）。故 `mdu.c` 的做法是：
1. C 把两个 32 位操作数（**大端**）写进 data 暂存 `mdu_s[8]`；
2. 一段**不透明 `__asm`** 把暂存搬进 R4-R7/R0-R3 → `mov DMAIR,#op` 触发 → 结果写回 `mdu_s`；
3. C 从 `mdu_s` 组装返回。

MDU 规格：`DMAIR`@0xED（**必须立即数写**）；arg1=R4-R7、arg2=R0-R3（大端）；
`0x02`=32 位乘(3clk)、`0x04`=32 位无符号除(19clk；商 R4-R7、余数 R0-R3；除零→0xFFFFFFFF)。
有符号除指令码见手册 §36.3.3（暂未实现）。**仿真不建模 MDU → 只能真机验证。**
