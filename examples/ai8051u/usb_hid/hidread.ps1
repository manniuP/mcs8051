param([int]$Vid=0x34BF,[int]$ProductId=0xFF01,[int]$Seconds=4,[int]$ReportLen=65)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Hid {
  [StructLayout(LayoutKind.Sequential)]
  public struct SP_DEVICE_INTERFACE_DATA { public int cbSize; public Guid InterfaceClassGuid; public int Flags; public IntPtr Reserved; }
  [StructLayout(LayoutKind.Sequential)]
  public struct HIDD_ATTRIBUTES { public int Size; public ushort VendorID; public ushort ProductID; public ushort VersionNumber; }
  [DllImport("hid.dll")] public static extern void HidD_GetHidGuid(out Guid g);
  [DllImport("hid.dll")] public static extern bool HidD_GetAttributes(IntPtr h, ref HIDD_ATTRIBUTES a);
  [DllImport("setupapi.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SetupDiGetClassDevs(ref Guid g, IntPtr enumerator, IntPtr hwnd, int flags);
  [DllImport("setupapi.dll", CharSet=CharSet.Unicode)] public static extern bool SetupDiEnumDeviceInterfaces(IntPtr h, IntPtr devInfo, ref Guid g, int index, ref SP_DEVICE_INTERFACE_DATA d);
  [DllImport("setupapi.dll", CharSet=CharSet.Unicode)] public static extern bool SetupDiGetDeviceInterfaceDetail(IntPtr h, ref SP_DEVICE_INTERFACE_DATA d, IntPtr detail, int size, out int required, IntPtr devInfo);
  [DllImport("setupapi.dll")] public static extern bool SetupDiDestroyDeviceInfoList(IntPtr h);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] public static extern IntPtr CreateFile(string path, uint access, uint share, IntPtr sec, uint disp, uint flags, IntPtr tmpl);
  [DllImport("kernel32.dll", SetLastError=true)] public static extern bool ReadFile(IntPtr h, byte[] buf, uint n, out uint read, IntPtr ov);
  [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@

$guid = New-Object Guid
[Hid]::HidD_GetHidGuid([ref]$guid)
$DIGCF_PRESENT = 0x2; $DIGCF_DEVICEINTERFACE = 0x10
$hDev = [Hid]::SetupDiGetClassDevs([ref]$guid, [IntPtr]::Zero, [IntPtr]::Zero, $DIGCF_PRESENT -bor $DIGCF_DEVICEINTERFACE)
if ($hDev -eq [IntPtr]::Zero -or $hDev -eq [IntPtr](-1)) { Write-Output "SetupDiGetClassDevs failed"; exit }

$found = 0
$idx = 0
while ($true) {
  $did = New-Object Hid+SP_DEVICE_INTERFACE_DATA
  $did.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($did)
  if (-not [Hid]::SetupDiEnumDeviceInterfaces($hDev, [IntPtr]::Zero, [ref]$guid, $idx, [ref]$did)) { break }
  $idx++
  $need = 0
  [void][Hid]::SetupDiGetDeviceInterfaceDetail($hDev, [ref]$did, [IntPtr]::Zero, 0, [ref]$need, [IntPtr]::Zero)
  if ($need -le 0) { continue }
  $buf = [Runtime.InteropServices.Marshal]::AllocHGlobal($need)
  $cb = if ([IntPtr]::Size -eq 8) { 8 } else { 5 }
  [Runtime.InteropServices.Marshal]::WriteInt32($buf, $cb)
  if (-not [Hid]::SetupDiGetDeviceInterfaceDetail($hDev, [ref]$did, $buf, $need, [ref]$need, [IntPtr]::Zero)) { [Runtime.InteropServices.Marshal]::FreeHGlobal($buf); continue }
  $path = [Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buf, 4))
  [Runtime.InteropServices.Marshal]::FreeHGlobal($buf)

  if ($path -notmatch '(?i)vid_34bf') { continue }
  $OPEN_EXISTING=3
  $access = [Convert]::ToUInt32("C0000000",16)
  $h = [Hid]::CreateFile($path, $access, 3, [IntPtr]::Zero, $OPEN_EXISTING, 0, [IntPtr]::Zero)
  if ($h -eq [IntPtr](-1)) { continue }
  $attr = New-Object Hid+HIDD_ATTRIBUTES
  $attr.Size = [Runtime.InteropServices.Marshal]::SizeOf($attr)
  [void][Hid]::HidD_GetAttributes($h, [ref]$attr)
  if ($attr.VendorID -eq $Vid -and $attr.ProductID -eq $ProductId) {
    $found++
    Write-Output ("found HID VID_{0:X4} PID_{1:X4} : {2}" -f $attr.VendorID,$attr.ProductID,$path)
    $sw=[Diagnostics.Stopwatch]::StartNew()
    $cnt=0
    while($sw.Elapsed.TotalSeconds -lt $Seconds){
      $rb = New-Object byte[] $ReportLen
      $read=0
      if([Hid]::ReadFile($h,$rb,$ReportLen,[ref]$read,[IntPtr]::Zero)){
        $cnt++
        $m=[Math]::Min(16,[int]$read)
        Write-Output ("  report#{0} len={1} : {2}" -f $cnt,$read, (($rb[0..($m-1)] | ForEach-Object { '{0:x2}' -f $_ }) -join ' '))
        if($cnt -ge 6){ break }
      } else { Start-Sleep -Milliseconds 100 }
    }
    Write-Output ("  total reports read = {0}" -f $cnt)
    [void][Hid]::CloseHandle($h)
  } else {
    [void][Hid]::CloseHandle($h)
  }
}
[void][Hid]::SetupDiDestroyDeviceInfoList($hDev)
if ($found -eq 0) { Write-Output "no matching HID device (VID_$('{0:X4}' -f $Vid) PID_$('{0:X4}' -f $ProductId))" }
