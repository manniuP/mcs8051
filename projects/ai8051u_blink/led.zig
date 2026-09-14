//! led.zig — 流水灯图案生成（Zig 自举后端）。
//!
//! 与 C 的接口只有单字节参数 / 返回，因此命中 SDCC MCS-51 默认 ABI 的
//! “参数在 DPL、返回在 DPL”，无需额外约定。
//!
//! 目标：mcs51-freestanding（AI8051U 的 8 位兼容模式）。

/// 返回下一个点亮位（1 表示该位点亮）。
/// 等价于把 8 位图案循环左移一位；全 0 时从 P1.0 重新开始。
export fn led_next(cur: u8) u8 {
    const had_high: bool = (cur & 0x80) != 0; // 最高位（即将移出的那一位）
    var next: u8 = cur +% cur;                // 左移一位（丢弃最高位）
    if (had_high) next |= 1;                  // 最高位回卷到最低位
    if (next == 0) next = 1;                  // 全灭时从 P1.0 重新开始
    return next;
}
