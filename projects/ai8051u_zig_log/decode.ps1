# decode.ps1 — 解析 ai8051u_zig_log 的轻量二进制日志帧。
#
# 帧格式：0x7E, id_lo, id_hi, 参数…, 校验(XOR)。参数布局由本脚本的 $Table 决定
# （与设备端 log.zig 的 m.log(id, .{...}) 对应）。
#
# 用法： powershell -File decode.ps1 -Port COM8 [-Baud 115200] [-Seconds 8]

param(
    [string]$Port = 'COM8',
    [int]$Baud = 115200,
    [int]$Seconds = 8
)

# id -> @{ name; args = @('u8','u16','u32'…) }   （u8/u16/u32 的字节数）
$Table = @{
    0x0001 = @{ name = 'boot';  args = @() }
    0x0002 = @{ name = 'count'; args = @('u16') }
    0x0003 = @{ name = 'xy';    args = @('u8', 'u8') }
}
function ArgBytes([string]$t) { if ($t -eq 'u8') { 1 } elseif ($t -eq 'u16') { 2 } elseif ($t -eq 'u32') { 4 } else { 0 } }

$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
$sp.ReadTimeout = 2000
$sp.Open()
Write-Host "reading $Port @ $Baud for $Seconds s ..."
$buf = New-Object System.Collections.Generic.List[byte]
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    $n = $sp.BytesToRead
    if ($n -gt 0) {
        $tmp = New-Object byte[] $n
        [void]$sp.Read($tmp, 0, $n)
        $buf.AddRange($tmp)
    }
    Start-Sleep -Milliseconds 50
}
$sp.Close()

$b = $buf.ToArray()
$i = 0; $ok = 0; $bad = 0
while ($i -lt $b.Length) {
    if ($b[$i] -ne 0x7E) { $i++; continue }
    if ($i + 2 -ge $b.Length) { break }
    $id = [int]$b[$i + 1] + ([int]$b[$i + 2] -shl 8)
    $e = $Table[$id]
    if (-not $e) { $i += 1; continue }
    $plen = 0; foreach ($t in $e.args) { $plen += (ArgBytes $t) }
    if ($i + 3 + $plen -ge $b.Length) { break }
    $payload = @(); for ($k = 0; $k -lt $plen; $k++) { $payload += [int]$b[$i + 3 + $k] }
    $ck = [int]$b[$i + 3 + $plen]
    $xor = $b[$i + 1] -bxor $b[$i + 2]; foreach ($a in $payload) { $xor = $xor -bxor $a }
    $i = $i + 4 + $plen

    if ($xor -ne $ck) { $bad++; Write-Host ("[0x{0:x4}] BAD checksum" -f $id); continue }
    $ok++
    $vals = @(); $off = 0
    foreach ($t in $e.args) {
        $nb = ArgBytes $t
        $v = 0; for ($k = 0; $k -lt $nb; $k++) { $v = $v -bor ($payload[$off + $k] -shl (8 * $k)) }
        $vals += $v; $off += $nb
    }
    Write-Host ("[0x{0:x4}] {1,-6} {2}" -f $id, $e.name, ($vals -join ', '))
}
Write-Host "frames ok=$ok bad=$bad bytes=$($b.Length)"
