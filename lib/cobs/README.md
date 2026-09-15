# cobs —— 平台无关的 COBS 编码器 + 轻量二进制日志帧

把「日志」编码成一个**自定界、无 `0x00` 的字节流**写进**调用方提供的缓冲区**；
如何把它发出去（UART / USB / 环形队列 / 存 Flash / 单元测试）**完全由调用方决定**。

- **零平台依赖**：不含 SFR、内联汇编、`std`、堆分配；可编到 **mcs51 / mcs251 / 主机**。
- **单缓冲区、单趟编码**：直接在用户缓冲区里“先占位长度码、后回填”，无需第二缓冲区。
- **两份等价实现**：`cobs.zig`（Zig）与 `cobs.h` / `cobs.c`（C），供各自语言原生调用。

## 文件

| 文件 | 说明 |
| --- | --- |
| `cobs.zig` | Zig 接口（**单实例**，见下）。 |
| `cobs.h` / `cobs.c` | C 接口（**可重入**，结构体 + 显式句柄）。 |
| `cobs_zig_test.zig` | 主机往返测试（Zig）：`zig run lib/cobs/cobs_zig_test.zig` |
| `cobs_c_test.c` | 主机往返测试（C）：`zig cc lib/cobs/cobs_c_test.c lib/cobs/cobs.c -o t.exe; .\t.exe` |

用法示例见 `examples/ai8051u_zig_log/`（Zig）与 `examples/ai8051u_c_cobs/`（C）。

## COBS 简述

编码后**不出现 `0x00`**，于是可用单个 `0x00` 作为帧定界符：接收端按 `0x00` 切帧、
再做 COBS 解码即可，抗错位、无需转义。每块最多 254 个非零字节：

```
[长度码 = 本块字节数+1] [本块字节…]   遇到 0x00 即封块（该零不写出，由长度码隐含）
```

本实现对 `0x00` 与“满 254”两种情况封块；编码结果末尾再追加一个 `0x00` 作为帧定界。

## 日志帧格式

原始字节（随后整体做 COBS，再以 `0x00` 结束）：

```text
0x7E, id_lo, id_hi, 参数…, XOR 校验
```

参数编码：

| 函数 | 编码 |
| --- | --- |
| `logU8` | 1 字节 |
| `logU16` | 2 字节小端 |
| `logU32` | 4 字节小端 |
| `logVar` | 无符号 LEB128（变长，小值省字节） |
| `logStr` / `logBytes` | `LEB128(len)` + 原始字节 |

`XOR 校验` = `id_lo ^ id_hi ^ 所有参数字节`（**不含起始 `0x7E`**）。
主机端参考解码器：`examples/ai8051u_zig_log/decode.ps1`（先按 `0x00` 切帧 → COBS 解码 → 按 id 表解析）。

## Zig 接口

> **单实例限制**：当前 mcs 后端**尚不支持结构体字段访问**，故 Zig 版用模块级变量保存一份状态，
> 同一时刻只支持一个编码器。待后端支持结构体后，可改为调用方持有的 `Encoder`（与 C 版对齐）。

```zig
const cobs = @import("cobs");

var buf: [128]u8 = undefined;
cobs.initRaw(&buf, buf.len);        // 绑定用户缓冲区（指针 + 容量）

cobs.logBegin(0x0002);              // 每帧开始：重置 + 写 id
cobs.logU16(1234);
cobs.logVar(1234);
cobs.logStr("hi");
const n = cobs.logEnd();            // 写 XOR + COBS 收尾；n 为可发送长度（含 0x00）
if (n != 0) {
    const p = cobs.data();
    var i: u16 = 0;
    while (i < n) : (i += 1) uart_putc(p[i]);   // 输出方式由调用方决定
}
```

底层通用接口：`initRaw(buf, cap)` / `reset()` / `add(byte)` / `finish() u16` /
一次性 `encode(in, in_len, out, out_cap) u16`；以及 `data()` / `length()` / `overflow()`。

构建注入命名模块（`@import("cobs")`）：

```text
zig build-obj -target mcs251-freestanding \
  --dep cobs -Mcobs=<repo>/lib/cobs/cobs.zig -Mroot=<源> -femit-bin=out.asm
```

## C 接口

```c
#include "cobs.h"

static unsigned char out[128];
static void send(const unsigned char *p, unsigned int n) {
    unsigned int i; for (i = 0; i < n; i++) uart_putc(p[i]);
}

void main(void) {
    cobs_enc_t e;
    cobs_init(&e, out, sizeof out);          /* 可重入：状态由调用方持有 */
    cobs_log_begin(&e, 0x0002);
    cobs_log_u16(&e, 1234);
    unsigned int n = cobs_log_end(&e);       /* out[0..n) 可发送；n==0 表示不足 */
    if (n) send(out, n);
}
```

底层通用接口：`cobs_init` / `cobs_reset` / `cobs_putc` / `cobs_finish` /
一次性 `cobs_encode(in, in_len, out, out_cap)`。

## 约定与限制

- **容量**：一帧原始内容需能被缓冲区容下。COBS 最坏开销 ≈ `原始长度 + 原始长度/254 + 1`。
  超出时置 `overflow`，`finish()`/`logEnd()` 返回 `0`，调用方应丢弃该帧。
- **可重入性**：C 版可重入（每实例一个 `cobs_enc_t`）；Zig 版单实例（后端限制）。
- **`usize`/指针**：库只用指针（`[*]u8`）与 `u16` 长度；不依赖 `usize` 作为跨语言返回值。
- 两份实现（Zig/C）**保持同步**由主机测试保障：改动后请分别运行两个测试。

## 后端依赖（用于本仓库的 mcs251 目标）

在 AI8051U（mcs251）上要能用「调用方提供的任意缓冲区指针」，依赖后端两项能力（均已实现）：

1. **运行期指针 + 运行期下标**：`p[i]`（`p: [*]u8`，`i` 运行期）→ 3 字节绝对地址 + `@dr28`。
2. **编译期指针物化**：把 `&全局数组` / `@ptrFromInt` 这类编译期指针存入指针变量
   （`s_buf = buf`）→ 帧内 3 字节地址。

限制：以上均为 **mcs251 + xdata + 1 字节元素**；mcs51 下 Zig 版暂不可用（C 版无此限制）。

## 后续可推进

- 后端支持结构体字段访问后，把 Zig 接口改为 `Encoder` 结构体（可重入、多实例）。
- 支持多字节元素下标（如 `u16` 数组），以及 `data`/`idata`/`edata` 空间的运行期下标。
- 增加 CRC16（替代 XOR）、时间戳、按 id 的编译期字符串池（进一步省字节）。
- 接收端解析库（COBS 解码 + 帧解析）也做成 Zig/C 双接口，便于 MCU 间通信。
- 中断安全的环形发送队列，替代当前示例里的阻塞发送。
