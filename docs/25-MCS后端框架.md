# 25 MCS 后端框架（我们写的部分）

> 目标：把**自研 MCS-51/MCS-251 后端**的框架理清楚，方便后续迭代。**只梳理我们写的文件**；
> 上游 Zig 编译器源码**不动**（仅少量接入点，见 §4）。参考上游后端（如 `codegen/x86_64/`：
> `CodeGen.zig` + `Mir.zig` + `abi.zig` + `encoder/Encoding`）——我们的目录已按同样思路组织。

## 1. 管线总览

```
 Zig 源 --Sema--> AIR --generate()--> Gen（两遍）--emit--> Mir（label/inst/raw）
                                                              │
                                                   encode.formatInst（文本）
                                                              │
                                              link/Asx.updateFunc 包裹（.area/.globl/符号/trampoline）
                                                              │
                                                ASxxxx 汇编文本（.asm）--sdas--> .rel --sdld--> .ihx
```

要点：与上游「直接产目标字节」的后端不同，我们**产 ASxxxx 汇编文本**，编码/布局交给 SDCC 工具链。
因此 `Mir` 装的是「汇编文本层面的条目」（标签/指令/原样文本），`encode` 只做**文本**格式化，
真正落盘的 `.rel` 由 `sdas251`/`sdas8051` 生成。

## 2. 我们写的文件（都在 `compiler/src/codegen/mcs/` + 一个 `link/Asx.zig`）

| 文件 | 行数 | 职责 | 上游对应物 |
| --- | --- | --- | --- |
| `CodeGen.zig` | ~4.6k | **后端主体**：`Gen` 两遍降级 AIR→Mir；`generate`/`generateLazy` 入口；`legalizeFeatures`；`mangleNavSymbol`；`aggressiveSizeFor` | `x86_64/CodeGen.zig`（上游同样是大文件） |
| `Mir.zig` | ~120 | 汇编文本 IR：`Item = label/inst/raw`；`emit` 写出函数体 | `x86_64/Mir.zig` |
| `encode.zig` | ~405 | 文本编码：`Mnemonic`（65 族）、`Operand`（reg/imm/code/…）、`formatInst` | `x86_64/encoder.zig` / `Encoding.zig` |
| `forms.zig` | ~2.8k | **生成物**：65 族 / 769 种合法操作数形式（来自 sdas251 ISA 矩阵）；勿手改 | `x86_64/encodings.zon` |
| `abi.zig` | ~136 | SDCC MCS251 ABI rev2：按大小分类参数/返回值寄存器槽；纯函数+单测 | `x86_64/abi.zig` |
| `device.zig` | ~162 | 设备存储表视图（`MCS_DEVICE` JSON）：放置 `decide` + 标签 `parseSection`（放置/优化等级） | 无（本项目特有） |
| `link/Asx.zig` | ~265 | ASxxxx 输出驱动：`updateFunc` 渲染函数、`updateNav` 数据符号、`flush` 落盘；符号按 fqn 修饰 + 导出 trampoline | `x86_64/…` 对应的 link/文件 |

> `forms.zig` 由 `tools/gen_mcs_forms.py` 从 SDCC `sdas/as251/tests/instruction-forms.tsv` 生成；
> **指令覆盖面的唯一权威**，改指令集只改生成器/TSV 再重生成，不要手编。

## 3. `Gen`（`CodeGen.zig`）内部结构

- **值模型 `MCValue`**（AIR 值的位置）：`none`/`regs(abi.Primary)`/`acc`/`frame(disp)`/`incoming`/
  `ptr(base,off,len)`/`ptr_dyn`/`ptr_rt{…,space}`/`slice`。`Loc` 为操作数读取位置（多出 `imm`）。
- **两遍降级**：
  1. `// --- 第一遍：预分配帧槽 ---`（约 L512 起）：为 AIR 指令预分配帧槽/切片视图/绝对地址槽。
  2. `// --- 第二遍：发射指令 ---`（约 L1346 起）：按 AIR 发射 Mir，各指令族的 `emit*`。
- **分区注释**（照此定位）：`临时帧槽`(L274)、`帧内寻址`(L316)、`常量/立即值`(L357)、
  `位运算/移位/乘除`(L2407)、`重载/内置`(L2865)、`比较`(L3992)、`switch`(L4160)、`调用与返回`(L4309)。
- **帧差异**：MCS-251 为 **SPX 硬件栈帧**（`.frame` = prologue 后相对 SPX 的负位移）；
  MCS-51 为**静态 idata 帧**（`.area DSEG` + `_frkN` + `.ds`，正偏移、小端）。
- **入口**：`generate()` 装配 `Gen`（含 `ret_class`/`aggressive_size`/`cdb_*`）→ `genBody` → `finish`，
  返回 `Mir`；`generateLazy` 目前对编译器内置函数报「未实现」。

## 4. 上游接入点（这些是**上游文件**，只在加后端时改过，尽量不再动）

| 文件 | 接入 |
| --- | --- |
| `codegen.zig` | `.stage2_mcs => @import("codegen/mcs/CodeGen.zig")`；`AnyMir`、后端枚举 |
| `target.zig` | `arch = .mcs51/.mcs251` 的定义、`ofmt = .hex`、`stage2_mcs` 映射 |
| `Zcu.zig` | `.stage2_mcs => switch (cc) { .mcs251_sdcc, … => true }`（调用约定） |
| `Sema.zig` | 调用约定 `.mcs51_sdcc/.mcs251_sdcc` |
| `dev.zig` | `.mcs => switch (feature)`（`supports(.mcs_backend)`） |
| `codegen/llvm.zig` | LLVM 不可用时的守卫（MCS 无 LLVM） |

## 5. 迭代指南：改哪儿？

| 要做的事 | 改哪里 |
| --- | --- |
| 支持一条新 **AIR 指令** | `CodeGen.zig`：第一遍补预分配（若需帧槽）、第二遍 `emitBody` 的 switch 加 `emit*`；必要时扩 `MCValue` |
| 加/改一条**指令形式** | 改 `tools/gen_mcs_forms.py`（或 TSV）→ 重生成 `forms.zig`；若形态超出当前 `encode.Operand`，同步 `encode.zig` |
| 新**操作数/助记符** | `encode.zig` 的 `Mnemonic`/`Operand`/`formatInst`（`forms.zig` 提供合法性表） |
| **ABI** 变更 | `abi.zig`（并递增 `revision`）；受影响的两遍调用/返回代码在 `CodeGen.zig` 的「调用与返回」区 |
| **数据空间/放置/优化等级** | `device.zig`（解析/`decide`）+ `tools/mcs_device.py`（生成 `MCS_DEVICE` JSON）+ 设备 TOML |
| **段/符号/trampoline/调试** | `link/Asx.zig`（`updateNav`/`updateFunc`/`flush`）；Zig 调试符号在 `CodeGen` 的 `emitCdbLine` |
| 构建层优化（非编译器） | `tools/mcs_opt.py` 等，见 [24-优化器管线总览](24-优化器管线总览.md) |
| 重编编译器（自举） | `compiler/`：系统 zig 重建（见 `AGENTS.md`）；**需先经用户确认** |

## 6. 约定与坑

- **`forms.zig` 是生成物**：勿手编；它只描述合法性/示例，不含「如何取地址」——寻址与两遍策略在 `CodeGen`。
- **`Mir` 只装函数体**：`.area/.globl`/函数符号/导出 trampoline 由 `Asx` 包裹；`Mir.emit` 只输出函数体。
- **两遍必须一致**：第一遍的帧槽/标签分配与第二遍发射要对应；新增 AIR 指令时两遍都要动。
- **MCS-51 静态帧**：不要假设 SPX；帧槽是 idata 偏移、小端，与 MCS-251 相反。
- **调试符号只 `-ODebug`**：Release 档不产 `C$`/`G$`，以免污染体积基线（见 [17](17-后端IR提示与中间层优化.md)）。
- **别用切片越界**做元素访问（会生成 `Lxx` 标签，构建层已用 `fix_mcs_labels.py` 兜底，见 [06 §1.2](06-常见问题与限制.md)）。

## 7. 可选的后续结构整理

`CodeGen.zig` 已按分区注释成段，**与上游「大 CodeGen.zig + 辅助模块」保持一致**，暂不强行拆文件
（Zig 结构体方法不能跨文件，硬拆需改成自由函数或 `usingnamespace` 风格，收益有限）。若要拆，
建议按现有分区：`frame.zig`（帧/寻址）、`ops.zig`（位运算/算术）、`call.zig`（调用/返回）……并保持
`Gen` 单一定义、方法以 `fn (gen: *Gen, …)` 自由函数迁出。
