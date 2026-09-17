const std = @import("std");

test "mcs arch plumbing" {
    const Arch = std.Target.Cpu.Arch;

    try std.testing.expect(std.meta.stringToEnum(Arch, "mcs51") != null);
    try std.testing.expect(std.meta.stringToEnum(Arch, "mcs251") != null);

    try std.testing.expectEqual(std.builtin.Endian.little, Arch.mcs51.endian());
    try std.testing.expectEqual(std.builtin.Endian.big, Arch.mcs251.endian());

    try std.testing.expectEqual(@as(u16, 16), std.Target.ptrBitWidth_arch_abi(.mcs51, .none));
    try std.testing.expectEqual(@as(u16, 24), std.Target.ptrBitWidth_arch_abi(.mcs251, .none));

    try std.testing.expectEqual(Arch.Family.mcs51, Arch.mcs51.family());
    try std.testing.expectEqual(Arch.Family.mcs251, Arch.mcs251.family());

    const a = Arch.fromCallingConvention(.mcs251_sdcc);
    try std.testing.expectEqual(@as(usize, 1), a.len);
    try std.testing.expectEqual(Arch.mcs251, a[0]);

    _ = std.Target.mcs51.cpu.generic;
    _ = std.Target.mcs251.cpu.generic;
}

test "mcs lang plumbing" {
    _ = std.lang.AddressSpace.xdata;
    _ = std.lang.AddressSpace.code;
    _ = std.lang.AddressSpace.sfr;
    try std.testing.expectEqual(@as(u16, 6), @bitSizeOf(std.lang.AddressSpace));

    _ = std.lang.CallingConvention.mcs251_sdcc;
    _ = std.lang.CompilerBackend.stage2_mcs;
}
