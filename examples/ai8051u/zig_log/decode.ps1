# decode.ps1 — 解析 ai8051u_zig_log 的轻量二进制日志帧（COBS + 0x00 定界 + LEB128/字符串）。
#
# 传输：设备端把原始帧做 COBS 编码，以单个 0x00 结束（帧内无 0x00）。
# 原始帧：0x7E, id_lo, id_hi, 参数…, 校验(XOR)。参数按本脚本 $Table 的类型顺序解析：
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
    0x0006 = @{ name = 'g16';   args = @('u16') }
}

# COBS 解码：输入一段“不含 0x00 定界符”的编码数据，返回原始帧字节；非法返回 $null。
function Invoke-CobsDecode {
    param([byte[]]$Chunk)
    $out = New-Object System.Collections.Generic.List[byte]
    $idx = 0
    $n = $Chunk.Length
    while ($idx -lt $n) {
        $code = [int]$Chunk[$idx]; $idx++
        if ($code -eq 0) { return $null }
        for ($k = 1; $k -lt $code; $k++) {
            if ($idx -ge $n) { return $null }
            $out.Add($Chunk[$idx]); $idx++
        }
        if ($code -lt 255 -and $idx -lt $n) { $out.Add([byte]0) }
    }
    return ,$out.ToArray()
}

# 解析一帧原始字节（0x7E,id_lo,id_hi,参数…,XOR）。
function Read-Frame {
    param([byte[]]$Frame)
    if ($Frame.Length -lt 4 -or $Frame[0] -ne 0x7E) { return $false }
    $id = [int]$Frame[1] -bor ([int]$Frame[2] -shl 8)
    $e = $Table[$id]
    if (-not $e) { return $false }

    $p = 3
    $ck = $Frame[1] -bxor $Frame[2]
    $vals = New-Object System.Collections.Generic.List[string]

    foreach ($t in $e.args) {
        if ($t -eq 'str') {
            $len = 0; $shift = 0
            while ($true) {
                if ($p -ge $Frame.Length) { return $false }
                $x = $Frame[$p]; $ck = $ck -bxor $x; $p++
                $len = $len -bor (($x -band 0x7F) -shl $shift); $shift += 7
                if (($x -band 0x80) -eq 0) { break }
            }
            if ($p + $len -gt $Frame.Length) { return $false }
            $s = ''
            for ($k = 0; $k -lt $len; $k++) { $ck = $ck -bxor $Frame[$p]; $s += [char]$Frame[$p]; $p++ }
            $vals.Add('"' + $s + '"')
        } elseif ($t -eq 'var') {
            $v = 0; $shift = 0
            while ($true) {
                if ($p -ge $Frame.Length) { return $false }
                $x = $Frame[$p]; $ck = $ck -bxor $x; $p++
                $v = $v -bor (($x -band 0x7F) -shl $shift); $shift += 7
                if (($x -band 0x80) -eq 0) { break }
            }
            $vals.Add([string]$v)
        } else {
            $nb = if ($t -eq 'u8') { 1 } elseif ($t -eq 'u16') { 2 } elseif ($t -eq 'u32') { 4 } else { 0 }
            if ($p + $nb -gt $Frame.Length) { return $false }
            $v = 0
            for ($k = 0; $k -lt $nb; $k++) { $ck = $ck -bxor $Frame[$p]; $v = $v -bor ([int]$Frame[$p] -shl (8 * $k)); $p++ }
            $vals.Add([string]$v)
        }
    }
    if ($p -ge $Frame.Length) { return $false }

    $frameCk = $Frame[$p]
    if ($ck -ne $frameCk) { return $false }
    Write-Host ("[0x{0:x4}] {1,-6} {2}" -f $id, $e.name, ($vals -join ', '))
    return $true
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
$ok = 0; $bad = 0
$chunk = New-Object System.Collections.Generic.List[byte]
foreach ($byte in $b) {
    if ($byte -eq 0x00) {
        if ($chunk.Count -gt 0) {
            $frame = Invoke-CobsDecode -Chunk $chunk.ToArray()
            if ($frame -and (Read-Frame -Frame $frame)) { $ok++ } else { $bad++ }
            $chunk.Clear()
        }
    } else {
        $chunk.Add($byte)
    }
}
Write-Host "frames ok=$ok bad=$bad bytes=$($b.Length)"
