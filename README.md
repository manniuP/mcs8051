# mcs251

Zig + C toolchain workspace for Intel 8051 (MCS-51) and 80251 (MCS-251), targeting STC parts.

Plan: Zig frontend + a new self-hosted backend emitting SDCC/ASxxxx assembly; C goes through
`sdcc -mmcs51` / `sdcc -mmcs251`; final link with SDCC `sdld` and SDCC runtime. See `PLAN.md`.

## Layout

    mcs251/
      PLAN.md          checklist, ABI freeze, milestones
      docs/            Chinese guides: creating Zig + SDCC projects
      projects/        Buildable C + Zig projects (e.g. ai8051u_blink)
      examples/        Minimal examples
      include/         SDCC headers: c51.h, ai8051u_sfr.h, mcs_intrins.h
      port/            STC AI8051U HAL (SDCC) and target-description tests
      driver/          build orchestration (Zig -> asm -> sdas -> sdld, C -> sdcc)
      zig/             Zig compiler source, rebased onto upstream branch `0.16.x`, with the MCS backend
      sdcc-c251/       vendored SDCC fork with MCS-51 + MCS-251 targets, used as backend/reference

## Interop contract

- Target option: `-mmcs251` (SDCC), `-mmcs51` (SDCC)
- Adopt SDCC MCS251 ABI revision 2: `sdcc-c251/doc/mcs251/abi.md`
- Interop convention: `--stack-auto` / `__reentrant` on every translation unit
- Object/relocatable: SDCC ASxxxx `.rel`; final image: Intel HEX
- Instruction set reference: STC `AI8051U-*.md` appendix A

## Build

`zig/` is based on upstream `0.16.x` (`0.16.1-dev.29+7056ba9a5`) so it can be built by the
release compiler Zig 0.16.0 (installed via winget).  Point the compiler at the tree's own
`lib/` so `build.zig` and `std` match the source:

    $env:ZIG_LIB_DIR = "<workspace>\mcs251\zig\lib"
    & "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\zig.zig_Microsoft.Winget.Source_8wekyb3d8bbwe\zig-x86_64-windows-0.16.0\zig.exe" build -Dno-langref

The resulting compiler is `zig/zig-out/bin/zig.exe`.

Smoke test (MCS-251, void leaf function):

    & zig/zig-out/bin/zig.exe build-obj -target mcs251-freestanding -femit-bin=empty.asm empty.zig

## Status

The self-hosted MCS backend (`zig/src/codegen/mcs/`) builds and emits ASxxxx assembly for:

- 1-4 byte scalar parameters/returns with the ABI register slots (`DPL/DPH/B/A`);
- the first scalar parameter in registers, remaining scalars read from the reentrant
  hardware stack at the SDCC `-(2 + Σsize)` offsets (see `abi.md`);
- 1-4 byte integer `add`/`sub`/`and`/`or`/`xor` (byte-wise with a carry chain), `not`,
  and `shl`/`shr` with constant or variable shift counts;
- multiply (`mul ab`, `mul WR,WR`, and a 3×16×16 composition for 4 bytes) and
  divide/modulo (`div ab`, `div WR,WR`, restoring division for 3/4 bytes); signed
  division/modulo is done by `|a| / |b|` followed by sign fix-up (`@divTrunc`/`@divFloor`,
  `@rem`/`@mod`);
- an SPX stack frame on MCS-251 for temporaries and locals, with `inc/dec spx,#n`
  prologue/epilogue;
- control flow: `.block`/`.loop`/`.repeat`/`.br`/`.cond_br`/`.switch_br`, plus integer
  comparisons (signed and unsigned), `if`/`while`/`for` loops, and `switch` (equal-value
  and range cases lowered to a comparison chain);
- frame-backed locals (`.alloc`/`.load`/`.store`), integer casts
  (`.intcast`/`.trunc`/`.bitcast`, including sign extension and int<->pointer
  materialization), arrays (compile-time indices use a direct frame offset; runtime
  indices are expanded into a comparison chain over the constant indices), and aggregate
  value copies (constant aggregates via `Value.writeToMemory`, runtime copies byte-wise);
- slices (`.array_to_slice`/`.slice`/`.slice_len`/`.slice_ptr`/`.slice_elem_val`/
  `.slice_elem_ptr`/`.ptr_add`) of fixed-length objects: compile-time `ptr`+`len` collapse
  to a slice view; a materialized slice is a 6-byte `ptr`+`len` value (3-byte flat pointer
  kept in `DR28`), runtime indices are expanded over the known length, and pointers use
  `@DR28` dereference;
- direct calls (`.call`) and recursion (first scalar in `DPL/DPH/B/A`, remaining scalars
  pushed in reverse order), indirect calls (3-byte function pointer loaded into `DR28`
  via push/pop, then `ecall @dr28`), and variadic calls (`@cVaStart`/`@cVaArg`/`@cVaCopy`/
  `@cVaEnd`; the promoted `c_int` varargs are pushed with the fixed stack args and read
  through a 3-byte flat `va_list` using `@DR28`).

`MCS-51` keeps the register model for 1-3 byte scalars, fetches additional parameters
from the hardware stack at entry, and keeps locals, parameters and intermediates in a
**static idata frame** (`.area DSEG` / `_frkN` / `.ds`), i.e. the SDCC default
non-reentrant layout.  Callers push arguments (little-endian) and restore `SP` after the
call.
Still unimplemented (each reports a clear compile error): floats, runtime indexing of
unbounded slice/pointer values, and MCS-51 slices and indirect/variadic calls.  The
`sdas`/`sdld` link driver lives in `driver/`.

## Notes

- This is a fork-in-place workspace; `zig/` and `sdcc-c251/` are modified directly.
- Upstream revisions were copied without `.git`. Local changes are tracked by the root repo.
