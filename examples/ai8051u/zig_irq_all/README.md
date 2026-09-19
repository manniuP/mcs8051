# ai8051u_zig_irq_all — 全中断 ISR 保留验证

列出 Ai8051U **全部中断**的 ISR（向量地址见 STC 手册 15.3），用于验证：

> **不触发、甚至为空的 ISR，会不会被当死代码优化掉？**

结论：**不会，全部保留**。

- `irqall.zig`：每个中断一个 `export fn`，上方注释标注 **向量地址 + 触发源**。
  - **核心中断**（INT0–INT4、定时器 0–4/11、UART1–4、ADC/LVD/CMP/PCA/SPI/I2C/USB/RTC、
    I2S/QSPI、P0–P7）内部做 加/减/移位/位运算（改写全局 `acc`/`acc2`）。
  - **DMA / 次要中断**留空 `{}`，用来观察空函数是否保留。
- `crt0.asm`：完整向量表（54 个向量，含 0x0063→0x0083、0x00DB→0x0123 等稀疏空隙按 `.ds` 补齐），
  每条 `ejmp _<name>` 后注释触发源。
- `main` 不使能、不触发任何中断，只死循环。

## 为什么保留

1. ISR 都是 `export fn` → 编译期**导出根**，即使无人调用也会生成（导出 trampoline `_<name>`）。
2. crt0 向量表 `ejmp _<name>` 引用它们；`tools/mcs_dce.py`（若启用）把 keep 文件里的引用当根做可达性。
3. 后端条件融合等优化只在**函数内**，不删函数。

## 构建与验证

```powershell
xmake f --mcs_arch=mcs251
xmake build zigirqall       # 产物 build/examples/ai8051u/zig_irq_all/irqall.ihx
```

看符号与空函数（每个空 ISR 至少一条 `eret`，1 字节 `0xAA`）：

```powershell
Select-String irqall.map -Pattern '^C:'          # 所有 ISR 都在
Select-String irqall.lst -Pattern 'eret$'        # 55 条（= 空 + 非空 ISR 的收尾）
```

实测（默认 `-ODebug` 与 `-OReleaseSmall`）：`函数体=56、eret=55`，链接零 undefined。

> 唯一不出现的情况：ISR 既不 `export`、crt0 也没引用（= 未使用），那本就不生成。
