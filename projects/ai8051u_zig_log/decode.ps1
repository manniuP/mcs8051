# decode.ps1 — 解析 ai8051u_zig_log 的轻量二进制日志帧（含 LEB128 / 字符串）。
#
# 帧格式：0x7E, id_lo, id_hi, 参数…, 校验(XOR)。参数按本脚本 $Table 的类型顺序解析：
#   u8/u16/u32 = 小端定长；var = LEB128；str = LEB128(len) + len 字节。
#
# 用法： powershell -File decode.ps1 -Port COM8 [-Baud 115200] [-Seconds 8]

param(
    [string]$Port = 'COM8',
    [int]$Baud = 115200,
    [int]$Seconds = 8
)

$Table = @{
    0x0001 = @{ name = 'boot';  args = @() }
    0x0002 = @{ name = 'count'; args = @('u16') }
    0x0003 = @{ name = 'xy';    args = @('u8', 'u8') }
    0x0004 = @{ name = 'cvar';  args = @('var') }
    0x0005 = @{ name = 'msg';   args = @('str') }
}

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
    $id = [int]$b[$i + 1] -bor ([int]$b[$i + 2] -shl 8)
    $e = $Table[$id]
    if (-not $e) { $i++; continue }

    $p = $i + 3
    $ck = $b[$i + 1] -bxor $b[$i + 2]
    $vals = New-Object System.Collections.Generic.List[string]
    $incomplete = $false

    foreach ($t in $e.args) {
        if ($t -eq 'str') {
            # LEB128 长度
            $len = 0; $shift = 0
            while ($true) {
                if ($p -ge $b.Length) { $incomplete = $true; break }
                $x = $b[$p]; $ck = $ck -bxor $x; $p++
                $len = $len -bor (($x -band 0x7F) -shl $shift); $shift += 7
                if (($x -band 0x80) -eq 0) { break }
            }
            if ($incomplete) { break }
            if ($p + $len -gt $b.Length) { $incomplete = $true; break }
            $s = ''
            for ($k = 0; $k -lt $len; $k++) { $ck = $ck -bxor $b[$p]; $s += [char]$b[$p]; $p++ }
            $vals.Add('"' + $s + '"')
        } elseif ($t -eq 'var') {
            $v = 0; $shift = 0
            while ($true) {
                if ($p -ge $b.Length) { $incomplete = $true; break }
                $x = $b[$p]; $ck = $ck -bxor $x; $p++
                $v = $v -bor (($x -band 0x7F) -shl $shift); $shift += 7
                if (($x -band 0x80) -eq 0) { break }
            }
            if ($incomplete) { break }
            $vals.Add([string]$v)
        } else {
            $nb = if ($t -eq 'u8') { 1 } elseif ($t -eq 'u16') { 2 } elseif ($t -eq 'u32') { 4 } else { 0 }
            if ($p + $nb -gt $b.Length) { $incomplete = $true; break }
            $v = 0
            for ($k = 0; $k -lt $nb; $k++) { $ck = $ck -bxor $b[$p]; $v = $v -bor ([int]$b[$p] -shl (8 * $k)); $p++ }
            $vals.Add([string]$v)
        }
    }
    if ($incomplete) { break }
    if ($p -ge $b.Length) { break }

    $frameCk = $b[$p]; $p++
    $i = $p
    if ($ck -ne $frameCk) { $bad++; continue }
    $ok++
    Write-Host ("[0x{0:x4}] {1,-6} {2}" -f $id, $e.name, ($vals -join ', '))
}
Write-Host "frames ok=$ok bad=$bad bytes=$($b.Length)"
