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

## 下一步：二分 22 文件 diff

崩溃与"15:04 工作区（55MB 正常）→ 16:47 CodeGen.zig 修复"的时间线吻合，
但 mcs 后端代码在 x86 编译路径不执行，机制存疑。备选嫌疑（全局路径）：
Type.zig（ptrAbiAlignment 的 isPowerOfTwo 泛化）、Sema.zig（调用约定）、
Zcu.zig、codegen.zig 后端分发、link.zig File union（Asx case）。

计划：
1. `git checkout aa2ae08d -- zig/` 构建纯净 0.16.1（新缓存 .zig-cache-r2）：
   - 纯净版正常 → 崩溃在 MCS diff 内，按文件二分
   - 纯净版也崩 → 构建环境/bootstrap 问题，另查
2. 用 `git stash`/checkout 在 1bd19835 与 aa2ae08d 间切换，二分 22 文件
   （优先 Type.zig / Sema.zig / Zcu.zig / codegen.zig / link.zig）
3. 找到后修复 → 构建带 .ptr_rt 的 zig.exe → 跑 ptrtest 全流程验证
   fill 生成 `mov @DR28` 间接写 → commit

## 其他备注

- 崩溃 exe 位置：`zig\.zig-cache-r1\o\206a9940...\zig.exe`（19:36 新编译）
- install 步骤报 PDB FileNotFound（缓存无 zig.pdb），非阻塞，直接用缓存内 exe
- PowerShell 传参给 zig 必须用数组形式；`cmd /c` 被沙盒禁止
- 构建命令：`zig build -Doptimize=ReleaseFast -Dversion-string=0.16.1
  --cache-dir <fresh> --global-cache-dir <fresh>`（约 7-10 分钟）
