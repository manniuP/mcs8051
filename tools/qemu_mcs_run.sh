#!/usr/bin/env bash
# qemu_mcs_run.sh —— 用 QEMU 的 MCS-251 机（stc32g144k246）跑我们的 .ihx，免真机烧录。
#
# 依赖：WSL 里已构建 qemu-system-mcs251（GPLv2 外部工具，勿并入 MIT 产物）。
#   构建见 docs/交接-2026-09-15.md §20；默认路径 $HOME/qemu-mcs/build/qemu-system-mcs251
#   （可用环境变量 QEMU_MCS 覆盖）。
#
# 注意：QEMU 只有文件后缀是 .hex 时才走 Intel HEX 载入器（.ihx 会被当 raw），
#   本脚本自动把 .ihx 复制成 /tmp/<name>.hex。
#
# 用法：
#   tools/qemu_mcs_run.sh [ihx]              # 前台起 QEMU，串口在 127.0.0.1:$PORT
#   tools/qemu_mcs_run.sh --smoke [ihx]      # 起 QEMU 跑 5 条命令自检后退出
#   PORT=6000 tools/qemu_mcs_run.sh          # 换端口
#
# 另一终端（或宿主）连：
#   python3 examples/ai8051u_cmd/host/cmd.py --tcp 127.0.0.1:5555 ping
#   python3 examples/ai8051u_cmd/host/cmd.py --tcp 127.0.0.1:5555 mul 0x12345678 2
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
QEMU="${QEMU_MCS:-$HOME/qemu-mcs/build/qemu-system-mcs251}"
MACHINE="${MACHINE:-stc32g144k246}"
PORT="${PORT:-5555}"
SMOKE=0
IHX=""

for a in "$@"; do
  case "$a" in
    --smoke) SMOKE=1 ;;
    *) IHX="$a" ;;
  esac
done
: "${IHX:=$REPO/examples/ai8051u_cmd/cmd.ihx}"

[ -x "$QEMU" ] || { echo "找不到 QEMU：$QEMU（用 QEMU_MCS 指定）"; exit 1; }
[ -f "$IHX" ]  || { echo "找不到固件：$IHX"; exit 1; }

HEX="/tmp/$(basename "${IHX%.*}").hex"
cp -f "$IHX" "$HEX"
echo "QEMU  : $QEMU"
echo "固件  : $IHX  ->  $HEX"
echo "串口  : 127.0.0.1:$PORT（TCP chardev）"

"$QEMU" -M "$MACHINE" -bios "$HEX" \
  -chardev "socket,id=s0,host=127.0.0.1,port=$PORT,server=on,wait=off" \
  -serial chardev:s0 -display none -monitor none &
QPID=$!
trap 'kill "$QPID" 2>/dev/null || true' EXIT

sleep 1.5

if [ "$SMOKE" = "1" ]; then
  CMDPY="$REPO/examples/ai8051u_cmd/host/cmd.py"
  # 注意：mul/div 走 AI8051U 的 MDU（DMAIR@0xED），而 QEMU 的 0xED 是 TFPU →
  # 这两条**无法仿真**，只能真机。此处只冒烟可仿真的部分。
  for c in "ping" "led 1" "echo hello"; do
    echo "### $c"
    python3 "$CMDPY" --tcp "127.0.0.1:$PORT" -w 1.5 $c || echo "(失败)"
  done
  echo "### cordictest（随机对拍 Python math）"
  python3 "$CMDPY" --tcp "127.0.0.1:$PORT" -w 0.2 cordictest || echo "(失败)"
  echo "（mul/div = MDU，需真机：python3 $CMDPY -p COM8 mul 0x12345678 2）"
  exit 0
fi

echo "QEMU 运行中（Ctrl+C 退出）。另一终端："
echo "  python3 $REPO/examples/ai8051u_cmd/host/cmd.py --tcp 127.0.0.1:$PORT ping"
wait "$QPID"
