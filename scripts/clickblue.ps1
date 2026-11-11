# Presses the IDE's primary (blue) button once (Run Command / Save / Approve), for a request already read and judged safe. Never loops.
param([string]$Match = $env:UCR_WINDOW)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class B {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
}
"@
[void][B]::SetProcessDPIAware()
& "$PSScriptRoot\win.ps1" -Do raise -Match $Match | Out-Null
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) { "REFUSED: could not bring the IDE window to the front"; exit 3 }
Start-Sleep -Milliseconds 800
$b = New-Object System.Drawing.Bitmap 1920,1080; $g = [System.Drawing.Graphics]::FromImage($b); $g.CopyFromScreen(0,0,0,0,$b.Size); $g.Dispose()
$found = $null
foreach ($x in 450,600,800) { $run = 0; for ($y = 100; $y -lt 1000; $y++) { $c = $b.GetPixel($x,$y); if ($c.R -lt 30 -and [Math]::Abs($c.G-95) -lt 25 -and [Math]::Abs($c.B-184) -lt 30) { $run++; if ($run -ge 22) { $found = @($x,($y-11)); break } } else { $run = 0 } }; if ($found) { break } }
$b.Dispose()
if (-not $found) { "NO BLUE BUTTON"; exit 4 }
[void][B]::SetCursorPos($found[0],$found[1]); Start-Sleep -Milliseconds 300; [B]::mouse_event(2,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 120; [B]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
"clicked blue button at $($found[0]),$($found[1])"
