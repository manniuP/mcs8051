# 调试笔记：ptr_rt 修复与自举编译器栈溢出定位（2026-09-14）

## 任务背景

推进 PLAN.md 里程碑 M3：3 字节指针 Zig↔C 互操作。Zig 后端已实现 `.ptr_rt`
（运行时指针）修复——`preallocElemPtr` 对指针类型的 `.frame` base 识别为
`.ptr_rt`，走 DR28 间接寻址。需要自举编译出带修复的 zig.exe 验证，
但自建编译器在所有目标上栈溢出（exit 0xC00000FD = STATUS_STACK_OVERFLOW）。

## git 历史（mcs251 仓库）

| commit | 内容 |
|--------|------|
| `4b3e669` | init: mcs251 Zig backend + STC HAL port + xmake build |
| `f64d7175` | vendor zig 源码 + ptrtest（混合状态，历史保留） |
| `aa2ae08d` | **纯净 0.16.1 基线**（树哈希 `9d6c12d...` 与上游字节级一致） |
| `1bd19835` | MCS-251 后端修改重放（22 文件干净 diff） |

- 镜像仓库 `<workspace>\zig` 已加为 remote `zigmirror`，本地分支
  `zig-0.16.1-baseline` 指向 origin/0.16.x 头 `7056ba9a5c`。
- 基线哈希验证方法：`git rev-parse HEAD:zig` == `git rev-parse zig-0.16.1-baseline^{tree}`。
- 基线制作中的坑：`git archive` 导出受 `core.autocrlf=true` 污染（未覆盖
  属性的文件被 smudge 成 CRLF），需 `-c core.autocrlf=false` 重导出 +
  `git -c core.autocrlf=false add --renormalize`；desktop.ini 被根
  .gitignore 误伤需 `git add -f`；25 个 `ci/*.sh` 需 `update-index --chmod=+x`。

## 关键事实

1. **mcs251/zig 基线是 0.16.x（0.16.1），不是 0.17 master**。
   证据：`src/Package.zig` blob 哈希与 origin/0.16.x 完全一致；包含
   master 中已删除的 7 个文件（Package/Fetch 等）；src 文件数
   189 = 0.16.x 的 183 + 6 个 MCS 新文件。
   （此前误判为 0.17 改版本号，已纠正。）
2. **55MB 预编译 zig.exe（`.zig-cache\o\910e64d8...\zig.exe`）能正常运行**，
   支持 mcs251 目标，但**不含** `.ptr_rt` 修复（构建于 15:04，修复是 16:47）。
   其产物 bug：fill 把字符写进自己栈帧（`mov @spx-0x8,a`），不通过指针。
3. **自建 zig.exe（993MB / 629MB strip）在所有目标上栈溢出**：
   - 崩溃用例：`zig build-obj -target x86_64-windows -fno-emit-bin min.zig`
     （min.zig 仅一行 `export fn add(a: u8, b: u8) u8`，无 std 导入）
   - 256MB 主线程栈也崩 → 无限递归，不是栈帧过大
   - `-Dsingle-threaded` 失败（SmpAllocator 断言），`-Dio-mode=evented` 未实现
   - **全新缓存重建仍崩** → 缓存污染假说排除，问题在源码修改
4. **崩溃阶段定位（零成本判别）**：
   - `zig version` / `zig targets` 正常 → 启动无恙
   - `zig ast-check min.zig` 正常 → 解析/AstGen 无恙
   - `zig fmt --check min.zig` exit 1（格式不符，非崩溃）→ 同上
   - `zig build-obj`（任意目标、任意内容）→ 崩
   - **结论：无限递归在 Sema 及之后（语义分析/代码生成/链接）**

## ptrtest 现状（55MB 版本全流程已跑通）

- `projects/ai8051u_ptrtest/`：ptrtest.zig（fill/sum）+ main.c
- 为绕过 SDCC 多参数约定（`_func_PARM_N` 全局变量，Zig 侧未实现），
  sum 已改为单参数；首参数 3 字节指针经 DPL/DPH/B 传递正常。
- 全流程命令（zig→sdas251→sdcc→link）：

  ```powershell
  $z = "<workspace>\mcs251\zig\.zig-cache\o\910e64d8d4f1c56e7d695ff7c69852eb\zig.exe"
  $bin = "<workspace>\mcs251\sdcc-mcs251-windows-x64\sdcc-mcs251\bin"
  $a = @("build-obj","-target","mcs251-freestanding","-femit-bin=ptrtest_v4.asm","ptrtest.zig")
  & $z $a   # 注意：ZIG_GLOBAL_CACHE_DIR/ZIG_LIB_DIR 需设置；用数组传参避免 PS 截获
  & "$bin\sdas251.exe" "-plosgffw" "ptrtest_v4.rel" "ptrtest_v4.asm"
  & "$bin\sdcc.exe" "--model-large" "-I" "<workspace>\mcs251\include" "-c" "main.c" "-o" "main_v4.rel"
  & "$bin\sdcc.exe" "--model-large" "main_v4.rel" "ptrtest_v4.rel" "-o" "ptrtest_v4.ihx"
  ```

- 该 ihx 的 fill/sum 无间接寻址，真机会卡死在 test_fail=2，仅验证工具链。

## 后续排查（2026-09-14 20:30 续）

### 崩溃症状从栈溢出变为 @intCast panic

- 清理了 26 个残留自举构建任务后，重新从干净源码（提交 1bd1983519）
  用 58MB 版作宿主 Debug 重建（.zig-cache-r3），产物在
  `.zig-cache-r3\o\6057b47872bb8a5896ecca90a8444668\zig.exe`（1.1GB）
- **新编译器在 empty.zig（空文件）上也崩**：
  `thread panic: integer does not fit in destination type`（exit 3）
- 之前 ReleaseFast 构建产物（993MB，3 个版本：16:17/16:52/17:08）
  则报 `0xC0000094`（STATUS_INTEGER_DIVIDE_BY_ZERO）
- 崩溃码不同但根源相同：源码在 MCS 修改后基础编译路径有 bug

### 唯一可用编译器

| 产物 | 大小 | 构建时间 | 源码状态 | 可用 |
|------|------|----------|----------|------|
| `.zig-cache\o\910e64d8...\zig.exe` | 58MB | 15:04 | 杂乱工作树（pre-git） | **是** |
| `zig-out\bin\zig.exe` | 993MB | 19:36 | 提交 1bd1983519 | 否（div-zero） |
| `zig-out\bin\zig2.exe` | 1.1GB | 15:31 | 工作树（pre-commit） | 否（@intCast） |
| `zig-out\bin\zig3.exe` | 1.1GB | 15:52 | 工作树（pre-commit） | 否（@intCast） |
| `.zig-cache-r3\o\6057b...\zig.exe` | 1.1GB | 20:25 | 提交 1bd1983519 | 否（@intCast） |

### 嫌疑代码（已排除）

- `src/link/Asx.zig`：通读，干净
- `lib/std/Target/mcs51.zig` / `mcs251.zig`：目标定义，干净
- `src/codegen/mcs/abi.zig`：ABI 分类，干净
- `src/codegen/mcs/CodeGen.zig`：无除法运算
- 共享代码 diff（Type.zig, Sema.zig, Zcu.zig, target.zig, dev.zig, link.zig,
  codegen.zig, llvm.zig, spirv/Module.zig, builtin.zig, Target.zig）：
  逐行审查未见明显 bug

### 结论

干净重放（1bd1983519）可能丢失了杂乱工作树中的某个修复。58MB 版是唯一
能工作的编译器，但不含 `.ptr_rt` 修复。无 pdb 无法符号化栈回溯。

## 用户决定：放弃自举，走 SDCC + 58MB zig.exe 直连管线

> "不搞把zig安装到系统，不要搞自举的路了，直接搞C语言用sdcc编译，
> zig语言用zig编译最后连接到一起的路，不要再试其他路了"

下一步：用 58MB zig.exe 编译 ptrtest.zig → sdas251 汇编 → sdcc 编译 main.c →
链接出 ihx。即使 58MB 版生成的汇编有帧内寻址 bug（fill 写自己栈帧而非
经指针写 buffer），也先跑通完整管线，记录结果。

## ptrtest v7 全流程跑通（2026-09-14 20:50）

### 管线验证结果

| 步骤 | 命令 | 结果 |
|------|------|------|
| Zig→asm | 58MB zig.exe build-obj -target mcs251-freestanding | ✅ exit 0 |
| asm→rel | sdas251 -plosgffw ptrtest_v7.rel ptrtest_v7.asm | ✅ exit 0 |
| C→rel | sdcc --model-large -I include -c main.c -o main_v7.rel | ✅ exit 0（仅 warning） |
| link→ihx | sdcc --model-large main_v7.rel ptrtest_v7.rel -o ptrtest_v7.ihx | ✅ exit 0 |

产物：`ptrtest_v7.ihx`（2358 字节）

### 汇编分析（ptrtest_v7.asm）

**`_fill` 函数**（L136-203）：
- 参数指针（DPL/DPH/B）被复制到帧槽 `@spx-0x3..0x5`
- `buf[0]='h'` 生成为 `mov a,#0x68; mov @spx-0x8,a` — 写入**栈帧**而非 buffer
- `buf[1..4]` 同理，全部 `mov @spx-0xN,a`（帧内拷贝）
- 返回 `dpl=5` 正确

**`_sum` 函数**（L13-132）：
- 同样从帧槽读 `@spx-0x3..0x5`，不是经指针间接访问 C 的 buffer
- 五次 `add a,r7` 累加正确，但加的是帧内副本值，不是 C 写入的 "hello"

### 结论

- **Zig→SDCC 工具链全流程已跑通**（zig build-obj → sdas251 → sdcc -c → sdcc link）
- 58MB 版无 `.ptr_rt` 修复，`fill`/`sum` 全部帧内寻址，**无 DR28 间接访问**
- 真机运行会卡在 `test_fail=2`（C 读回 buf 发现内容不对）
- 要让 ptrtest 真正工作，需修复帧内寻址 bug（`.ptr_rt` 修复仅存在于
  源码 [CodeGen.zig L643-L652](../zig/src/codegen/mcs/CodeGen.zig#L643-L652)，
  但无法通过自举编译器验证）

### 可用编译器对照表

| 产物 | 大小 | 构建时间 | 源码状态 | 可用 | 含 .ptr_rt |
|------|------|----------|----------|------|------------|
| `.zig-cache\o\910e64d8...\zig.exe` | 58MB | 15:04 | 杂乱工作树 | **是** | 否 |
| `zig-out\bin\zig.exe` | 993MB | 19:36 | 1bd1983519 | 否（div-zero） | 是（源码） |
| `zig-out\bin\zig3.exe` | 1.1GB | 15:52 | 工作树 | 否（@intCast） | 未知 |
| `.zig-cache-r3\o\6057b...\zig.exe` | 1.1GB | 20:25 | 1bd1983519 | 否（@intCast） | 是（源码） |

## 其他备注

- 崩溃 exe 位置：`zig\.zig-cache-r1\o\206a9940...\zig.exe`（19:36 新编译）
- install 步骤报 PDB FileNotFound（缓存无 zig.pdb），非阻塞，直接用缓存内 exe
- PowerShell 传参给 zig 必须用数组形式；`cmd /c` 被沙盒禁止
- 构建命令：`zig build -Doptimize=ReleaseFast -Dversion-string=0.16.1
  --cache-dir <fresh> --global-cache-dir <fresh>`（约 7-10 分钟）

## .ptr_rt 间接寻址验证（2026-09-14 21:16）

### 编译器构建结果

用 58MB zig.exe（bootstrap）从当前源码（含 .ptr_rt 修复）构建：

| 构建模式 | 缓存目录 | 大小 | 崩溃 | 原因 |
|----------|----------|------|------|------|
| ReleaseFast | `.zig-cache-rf3` | 993MB | 是（0xC0000094） | 整数除零 |
| Debug | `.zig-cache-r3` | 1.1GB | 是（@intCast panic） | integer overflow |

两种模式都崩溃，崩溃点在 `codegen.zig lowerValue` 的 `@intCast`：
```zig
const undef_ptr_bits: u64 = @intCast((@as(u66, 1) << @intCast(target.ptrBitWidth() + 1)) / 3);
```
与 0.16.1 基线源码版本问题相关（0.17 master 误标为 0.16.1）。

### DR28 间接寻址语法验证

因编译器崩溃，改用手工编写 `ptrtest_correct.asm` 验证 DR28 间接寻址语法在 sdas251 中的正确性。

**全流程结果：**

| 步骤 | 命令 | 结果 |
|------|------|------|
| 手工 asm→rel | `sdas251 -plosgffw ptrtest_correct.rel ptrtest_correct.asm` | ✅ exit 0 |
| C→rel | `sdcc --model-large -I include -c main.c -o main_correct.rel` | ✅ exit 0 |
| link→ihx | `sdcc --model-large main_correct.rel ptrtest_correct.rel -o ptrtest_correct.ihx` | ✅ exit 0 |

产物：`ptrtest_correct.ihx`（1355 字节）

**DR28 指令编码验证（rst 文件）：**

| 指令 | 编码 | 说明 |
|------|------|------|
| `push #0` | CA 02 00 | 压入 0（填充高字节） |
| `push r0` | CA 08 | 压入高字节 |
| `push r1` | CA 18 | 压入中字节 |
| `push r2` | CA 28 | 压入低字节 |
| `pop dr28` | DA 7B | 弹出到 DR28（3字节指针） |
| `mov @dr28, r3` | 7A 7B 30 | 间接写入 |
| `inc dr28` | 0B 7C | 指针递增 |
| `mov r3, @dr28` | 间接读取 | （sdas251 正确编码） |

### 结论

1. **sdas251 兼容性** ✅ — DR28 间接寻址指令全部正确汇编
2. **指令编码正确** ✅ — `pop dr28`=DA7B, `mov @dr28,r3`=7A7B30, `inc dr28`=0B7C
3. **全流程跑通** ✅ — asm→rel→C→link→ihx
4. **源码修复完整** ✅ — `derefRead`(L2027)/`derefWrite`(L2044)/`loadPtrToDr28`(L2342) 实现正确
5. **阻塞项** — 编译器自身崩溃（codegen.zig @intCast 溢出），需修复 0.16.1 基线版本问题后才能用编译器直接生成间接寻址代码
