# Acts only on the window whose title matches -Match. Every input first brings that window to the front,
# waits until the person has stopped using the machine (4 s idle), and refuses otherwise.
# -Do: info | raise | max | click (window-relative X,Y) | keys (SendKeys text) | paste (clipboard + Ctrl+V) | close
param([string]$Do, [int]$X, [int]$Y, [string]$Text, [string]$Shot, [string]$Match = $env:UCR_WINDOW)
if (-not $Match) { "Set -Match <window title regex> or the UCR_WINDOW environment variable"; exit 2 }
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class U {
 public delegate bool E(IntPtr h, IntPtr p);
 [DllImport("user32.dll")] public static extern bool EnumWindows(E e, IntPtr p);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
 [StructLayout(LayoutKind.Sequential)] public struct R { public int L,T,Rt,B; }
}
"@
Add-Type -Name D -Namespace P -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
[void][P.D]::SetProcessDPIAware()
$script:found = [IntPtr]::Zero; $script:title = ""
$cb = [U+E]{ param($h,$p) if ([U]::IsWindowVisible($h)) { $s = New-Object System.Text.StringBuilder 512; [void][U]::GetWindowText($h,$s,512); if ($s.ToString() -match $Match) { $script:found = $h; $script:title = $s.ToString(); return $false } } return $true }
[void][U]::EnumWindows($cb,[IntPtr]::Zero)
if ($script:found -eq [IntPtr]::Zero) { "NO WINDOW with $Match"; exit 2 }
$h = $script:found
$r = New-Object U+R; [void][U]::GetWindowRect($h,[ref]$r)
Add-Type -Name K -Namespace P -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte v, byte s, uint f, UIntPtr e); [StructLayout(LayoutKind.Sequential)] public struct L { public uint s; public uint t; } [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref L l);'
function Front {
	if ([U]::GetForegroundWindow() -ne $h) {
		# Only take focus once the person has stopped using the machine.
		$quiet = $false
		for ($i = 0; $i -lt 90 -and -not $quiet; $i++) { $l = New-Object P.K+L; $l.s = 8; [void][P.K]::GetLastInputInfo([ref]$l); if (([Environment]::TickCount - $l.t) -ge 4000) { $quiet = $true } else { Start-Sleep -Milliseconds 500 } }
		if (-not $quiet) { "REFUSED: machine still in use after 45 s"; exit 3 }
		[P.K]::keybd_event(0x12,0,0,[UIntPtr]::Zero); [P.K]::keybd_event(0x12,0,2,[UIntPtr]::Zero)
		# Restore only a minimized window, so a maximized one stays maximized.
		if ([U]::IsIconic($h)) { [void][U]::ShowWindow($h,9) }; [void][U]::SetForegroundWindow($h); Start-Sleep -Milliseconds 400
	}
	if ([U]::GetForegroundWindow() -ne $h) { "REFUSED: target window is not in front"; exit 3 }
}
switch ($Do) {
 "raise" { Front; "raised" }
 "max" { Front; [void][U]::ShowWindow($h,3); "maximized" }
 "info" { "title=[$($script:title)] rect=$($r.L),$($r.T) $($r.Rt-$r.L)x$($r.B-$r.T) front=$([U]::GetForegroundWindow() -eq $h)" }
 "click" { Front; [void][U]::SetCursorPos($r.L+$X,$r.T+$Y); Start-Sleep -Milliseconds 120; [U]::mouse_event(2,0,0,0,[UIntPtr]::Zero); [U]::mouse_event(4,0,0,0,[UIntPtr]::Zero); "clicked $X,$Y" }
 "keys" { Front; [System.Windows.Forms.SendKeys]::SendWait($Text); "keys sent" }
 "paste" { Front; [System.Windows.Forms.Clipboard]::SetText($Text); [System.Windows.Forms.SendKeys]::SendWait("^v"); "pasted" }
 "close" { [void][U]::PostMessage($h,0x10,[IntPtr]::Zero,[IntPtr]::Zero); "close sent to [$($script:title)]" }
}
if ($Shot) { Start-Sleep -Milliseconds 500; [void][U]::GetWindowRect($h,[ref]$r); $b = New-Object System.Drawing.Bitmap ($r.Rt-$r.L),($r.B-$r.T); $g=[System.Drawing.Graphics]::FromImage($b); $d=$g.GetHdc(); [void][U]::PrintWindow($h,$d,2); $g.ReleaseHdc($d); $g.Dispose(); $b.Save($Shot); $b.Dispose(); "shot saved" }
