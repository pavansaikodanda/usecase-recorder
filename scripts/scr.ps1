# Whole-screen helpers: screenshot, Snipping Tool record shortcut, click / drag / wheel at absolute screen coordinates.
# -Do: record (Win+Shift+R) | click X Y | drag X Y X2 Y2 | wheel X Y -Delta n -Count c -Pause ms ;  -Shot path saves a full-screen PNG.
param([string]$Do, [int]$X, [int]$Y, [int]$X2, [int]$Y2, [int]$Delta = -120, [int]$Count = 1, [int]$Pause = 600, [string]$Shot)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices;
public class S {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, int d, UIntPtr e);
 [DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, UIntPtr e);
}
"@
[void][S]::SetProcessDPIAware()
function Tap([byte[]]$keys) { foreach ($k in $keys) { [S]::keybd_event($k,0,0,[UIntPtr]::Zero) }; Start-Sleep -Milliseconds 80; [array]::Reverse($keys); foreach ($k in $keys) { [S]::keybd_event($k,0,2,[UIntPtr]::Zero) } }
switch ($Do) {
 "record" { Tap ([byte[]](0x5B,0x10,0x52)); "sent Win+Shift+R" }
 "click" { [void][S]::SetCursorPos($X,$Y); Start-Sleep -Milliseconds 500; [S]::mouse_event(2,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 220; [S]::mouse_event(4,0,0,0,[UIntPtr]::Zero); "clicked $X,$Y" }
 "drag" { [void][S]::SetCursorPos($X,$Y); Start-Sleep -Milliseconds 300; [S]::mouse_event(2,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 300; for ($i=1;$i -le 12;$i++) { [void][S]::SetCursorPos($X+($X2-$X)*$i/12,$Y+($Y2-$Y)*$i/12); Start-Sleep -Milliseconds 60 }; Start-Sleep -Milliseconds 300; [S]::mouse_event(4,0,0,0,[UIntPtr]::Zero); "dragged" }
 "wheel" { [void][S]::SetCursorPos($X,$Y); Start-Sleep -Milliseconds 300; for ($i=0;$i -lt $Count;$i++) { [S]::mouse_event(0x800,0,0,$Delta,[UIntPtr]::Zero); Start-Sleep -Milliseconds $Pause }; "scrolled $Count x $Delta" }
}
if ($Shot) { $sz = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $b = New-Object System.Drawing.Bitmap $sz.Width,$sz.Height; $g = [System.Drawing.Graphics]::FromImage($b); $g.CopyFromScreen(0,0,0,0,$b.Size); $g.Dispose(); $b.Save($Shot); $b.Dispose(); "shot saved" }
