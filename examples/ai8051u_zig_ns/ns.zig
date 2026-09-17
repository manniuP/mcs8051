//! ns.zig — 命名空间同名函数的符号修饰验证（后端「符号命名空间修饰」）。
//!
//! 两个命名空间 `a`/`b` 各有一个 `foo`：符号按 fqn 修饰为 `_ns_a_foo`/`_ns_b_foo`，
//! 不再都叫 `_foo` 撞标签。`export fn main` 的符号是 trampoline `_main → _ns_main`。
//!
//! 期望（UART1 P3.1 @9600，反复打印）：`020c`
//!   a.foo(1) = 0x02，b.foo(2) = 0x0c —— 若同名函数被合并/串线，输出会明显不对。

const m = @import("mcs");

const a = struct {
    pub fn foo(x: u8) u8 {
        return x +% 1;
    }
};
const b = struct {
    pub fn foo(x: u8) u8 {
        return x +% 10;
    }
};

export fn main() void {
    m.uartInit(40_000_000, 9600);
    m.uartPuts("\r\nns dispatch:\r\n");
    while (true) {
        m.uartPutHex2(a.foo(1));
        m.uartPutHex2(b.foo(2));
        m.uartPuts("\r\n");
        var t: u16 = 0;
        while (t < 6000) : (t += 1) {}
    }
}
