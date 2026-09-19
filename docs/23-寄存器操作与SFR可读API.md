# 23 寄存器（SFR）操作与可读 API（设计）

> 本文原为**设计稿**：整理 SFR 访问的两种既有写法，并给出「可读 API」两个候选方案。
> **现状**：示例已改用生成的 `dev` 模块；生成器另出**寄存器对象** `dev.reg.*`（方案 B）与
> **C 风格固定地址指针** `dev.p.*`（配 `mcs_opt` **R6** 融为单条 `anl/orl/xrl dir8,#imm`）。
> 三个按风格分目录的示例见 §5。**方案 A（放宽签名）未单独做**（示例直接用 `dev.sfr.*`）。
> §3.4 已用重建编译器验证指令输出。

## 1. 原来方案：`@ptrFromInt` 直指针

```zig
const P1   = @as(*volatile u8, @ptrFromInt(0x90));
const P1M1 = @as(*volatile u8, @ptrFromInt(0x91));

P1M1.* &= ~@as(u8, 0x02); // P1.1 推挽
P1.*   = 0xfd;            // LED 亮
```

- 例：`examples/ai8051u/zig_led/led.zig`（`zigled`）。
- 依赖后端对 `@ptrFromInt(0x80..0xFF)` 生成 **direct**（见 [06 §1.2](06-常见问题与限制.md)）。
- 优点：像普通内存，最易读；不需要额外库。
- 缺点（实测 asm，`build/examples/ai8051u/zig_led/led.asm`）：
  - `P1M1.* &= ~0x02` → `mov a,0x91 / anl a,#0xfd / mov 0x91,a`（3 条）；
  - `P1.* = 0xfd` → `mov a,#0xfd / mov 0x90,a`（2 条）；
  - 得不到单条 `anl dir8,#imm` / `mov dir8,#imm`；
  - **位寻址指令（`setb/clr/cpl addr.bit`）无法用 Zig 运算符表达**。

## 2. 现方案：`mcs.sfr*` 宏库

```zig
const m = @import("mcs");
m.sfrAnd(0x91, ~@as(u8, 0x02));
m.sfrWrite(0x90, 0xfd);
m.bitClr(0x90, 1);
```

- 实现：`lib/mcs251.zig` 的 `sfrWrite/sfrOr/sfrAnd/bitSet/bitClr/bitCpl/sfrPtr`，
  全部 `comptime` 拼内联汇编。
- 优点（实测 asm，`build/examples/ai8051u/dev/led.asm`）：
  - `sfrAnd` → 单条 `anl 0x91,#0xfd`；`sfrWrite` → 单条 `mov 0x90,#0xfd`；
  - 位操作 `clr/setb/cpl addr.bit` 只有这条路径能做。
- 缺点：参数是**裸数字地址**，阅读时要对照手册；`dev.sfr.*` 是 `u16`，还得写
  `@intCast`，掩码要写 `~@as(u8, x)`，噪音大。

## 3. 可读 API 设计

目标：**保留融合指令与位操作**，同时让代码读得出寄存器名。

### 3.1 方案 A：放宽 helper 签名 + 命名别名（轻量，推荐）

1. 地址参数由 `comptime u8` 放宽为 `comptime u16`，内部 `@truncate`——使设备表生成的
   `dev.sfr.*`（`tools/mcs_sfr.py --emit zig`，`u16`）可直接传入，去掉 `@intCast`。
2. 新增 `pub const P1M1: u16 = 0x91;` 之类的**命名别名**（最好直接来自生成模块）。
3. 效果：

```zig
m.sfrAnd(dev.sfr.P1M1, ~@as(u8, 0x02)); // 读得出是 P1M1
```

- 改动量小、与现有调用**完全兼容**（旧调用传 `u8` 仍可）。
- 坑：后端对**文件级 `const` 也发 `_<name>` 数据符号**（见 `build/examples/ai8051u/dev/led.asm`
  的 `_P1M1_ADDR`），所以本分别名**勿与 `dev.sfr.*` 同名**，否则重名冲突
  （`examples/ai8051u/dev/led.zig` 里用 `P1M1_ADDR` 就是这个原因）。

### 3.2 方案 B：寄存器对象式 API（可选）

由设备模块生成**类型化寄存器**，方法内联：

```zig
const Reg = struct {
    addr: u16,
    pub inline fn anl(self: Reg, comptime mask: u8) void { ... } // and/or 是 Zig 关键字，不能用
    pub inline fn orl(self: Reg, comptime mask: u8) void { ... }
    pub inline fn set(self: Reg, comptime b: u3) void { ... }
    pub inline fn clr(self: Reg, comptime b: u3) void { ... }
};

P1M1.anl(~@as(u8, 0x02));
P1.orl(0x02);
P1.clr(1);
P1.set(1);
```

- 读法最接近 C：`P1M1.anl(...)` / `P1.clr(1)`。
- 前提：生成器要输出 `Reg{ .addr = ... }` 常量（`tools/mcs_sfr.py --emit zig` 扩展）。
- 命名限制：`and`/`or` 是 Zig 关键字，方法名用 `anl`/`orl`（或 `` @"and" ``，可读性差）。
- 兼容性：新 API，旧调用保留即可并存。

### 3.3 方案对比

| 维度 | 原方案 `@ptrFromInt` | 现方案 `mcs.sfr*` | A：放宽+别名 | B：寄存器对象 |
| --- | --- | --- | --- | --- |
| 可读性 | 高（`P1M1.* &= x`） | 低（裸地址） | 中高 | 高 |
| 单指令融合 | ✗（3 条） | ✓（1 条） | ✓ | ✓ |
| 位指令 `setb/clr` | ✗ | ✓ | ✓ | ✓ |
| 改动量 | — | — | 小 | 中（需生成器） |
| 兼容旧代码 | — | — | 完全 | 完全（并存） |

### 3.4 可行性验证（重建编译器实测）

用 `compiler/zig-out/bin/zig.exe`（mcs251-freestanding）编译最小样例，两种方案均生成单条指令：

```
anl 0x91,#0xfd      ; A/B 的 and
orl 0x90,#0x02      ; A/B 的 or
clr 0x90.1          ; B 的 .clr(1)
setb 0x90.1         ; B 的 .set(1)
```

即：`comptime u16` 地址 + `@truncate`、以及 `inline fn` + `comptime self` 的寄存器对象都能被后端折叠成最优指令。

## 4. 建议与落地步骤

- **先做 A**（签名放宽 + 命名别名），风险最小、立刻改善阅读；别名优先走设备表生成模块。
- B 作为设备表（`mcs251/docs/19` 待写）落地时一并生成，避免手写。
- 落地需改：`lib/mcs251.zig`（签名/别名）、`tools/mcs_sfr.py --emit zig`（B 的类型化输出）、
  相关示例（`ai8051u_dev`/`ai8051u_zig_led`）、以及 [06 §1.2](06-常见问题与限制.md) 的 API 列表。
- 兼容红线：放宽后旧调用不受影响；别名命名避开 `_<name>` 冲突。

## 5. 落地记录：示例已接入 `dev` 模块（2026-09-19）

- **xmake**：各纯 Zig 目标经 `--dep dev -Mdev=build/devices/device_sfr.zig` 注入生成的 SFR 模块，
  编译前用 `tools/mcs_sfr.py --emit zig` 刷新（`xmake/helpers.lua` 的 `ensure_device_sfr_zig`）。
- **示例**：`ai8051u_zig_{led,asm,bench,buzz,t0print,uart_echo}` 已改用 `dev.sfr.*`（按设备表地址，
  不再硬编码 `0xNN`）；本地别名命名避开 `dev.sfr.*`（后端会为二者各发 `_<name>` 符号）。
- **便携集**：`examples/ai8051u/zig_{t0print,uart_echo}/portable/build.zig` 同步加
  `--dep dev -Mdev=device_sfr.zig`；`tools/make_portable.ps1` 生成并拷入 `device_sfr.zig`。
- **方案 B 已实现**：`tools/mcs_sfr.py --emit zig` 额外生成 `Reg` 类型与 `reg` 命名空间
  （`dev.reg.P1M1.anl(~0x02)` / `dev.reg.P1.clr(1)` / `.write(v)` / `.read()` / `.set/.clr/.cpl`）；
  自包含（不依赖 `mcs` 模块），位语法按 `@import("builtin").cpu.arch` 选。
- **C 风格固定地址指针（`dev.p.*`）**：`tools/mcs_sfr.py --emit zig` 另生成
  `pub const p = struct { pub const P_SW1 = @as(*volatile u8, @ptrFromInt(0xba)); … };`，
  写法即 `dev.p.P_SW1.* &= ~0xc0;`。配合 `tools/mcs_opt.py` 的 **R6**，读-改-写融为单条
  `anl 0xba,#0x3f`（安全前提见 [24 §5](24-优化器管线总览.md)）；`mov a,#C ; mov dir8,a` 由
  R4 扩展为 `mov dir8,#C`。
- **三个示例（按风格分目录）**：
  - `examples/ai8051u/sfr_bits`（`xmake build zigsfrbits`）：**位指令**风格，`m.sfrAnd/sfrOr/bitSet/bitClr` + `dev.sfr.*`。
  - `examples/ai8051u/sfr_reg`（`xmake build zigsfrreg`）：**寄存器对象**，`dev.reg.*`（`anl/orl/set/clr/cpl/write/read`）。
  - `examples/ai8051u/sfr_ptr`（`xmake build zigsfrptr`）：**C 风格指针**，`dev.p.*`；产物
    `orl 0x92,#0x02` / `anl 0x91,#0xfd`（R6 单条）。
- **坑**：`dev.sfr.*` / `dev.reg.*` / `dev.p.*` 三套命名空间在**同一 `.zig` 里不要引用同一寄存器**
  （后端按短名发 `_<name>` 符号，会同名冲突）——故按风格拆成不同示例文件。
- **仍待做**：方案 A（放宽 `mcs` helper 签名为 `comptime u16`，省去 `@intCast`）；R4 对「函数最后一条
  `mov a,#C ; mov dir8,a`」因 `eret` 不可证 A 死而未触发（保守，见 [24 §5](24-优化器管线总览.md)）。
