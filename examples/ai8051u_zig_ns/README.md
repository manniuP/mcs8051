# ai8051u_zig_ns — 命名空间同名函数的符号修饰

验证 MCS-251 后端对**符号的命名空间修饰**：

- 函数体符号按 **fqn** 修饰（命名空间分隔符 → `_`）：`a.foo` → `_ns_a_foo`、`b.foo` → `_ns_b_foo`，
  不再都叫 `_foo` 而撞标签（旧行为：`sdas` 报重复符号 / 调用串线）。
- 导出符号用 **trampoline** 保持短名：`_main: ejmp _ns_main`，故 crt0/C 仍以 `_main` 引用。

两个 `foo` 做不同运算，运行期打印以确认调用路由正确：

```
ns dispatch:
020c
```

`a.foo(1)=0x02`、`b.foo(2)=0x0c`；若同名函数被合并/串线，输出会明显不对。

## 构建

```powershell
xmake f --mcs_arch=mcs251
xmake build zigns       # 产物 examples/ai8051u_zig_ns/ns.ihx
```

## 真机

STC-ISP（AiCube）选 `AI8051U-34K64`，烧 `ns.ihx`，串口（COMx @9600）应持续打印 `020c`。

## QEMU 无板仿真

```bash
wsl -e bash tools/qemu_mcs_run.sh \
  examples/ai8051u_zig_ns/ns.ihx
```
