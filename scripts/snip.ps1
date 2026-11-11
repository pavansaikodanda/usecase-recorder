# Lists or presses Snipping Tool buttons through Windows UI Automation (e.g. -Press "Start recording", -Press "^Stop").
param([string]$Press, [string]$Window)
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
$A = [System.Windows.Automation.AutomationElement]
$pids = @(Get-Process SnippingTool -ErrorAction SilentlyContinue | ForEach-Object Id)
$wins = $A::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition) | Where-Object { $pids -contains $_.Current.ProcessId }
foreach ($w in $wins) {
	"[window] $($w.Current.Name) class=$($w.Current.ClassName) rect=$($w.Current.BoundingRectangle)"
	if ($Window -and $w.Current.Name -notmatch $Window) { continue }
	foreach ($e in $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
		$t = $e.Current.ControlType.ProgrammaticName -replace 'ControlType\.',''
		if ($t -in 'Button','SplitButton','ToggleButton','MenuItem','Edit','CheckBox','Text') {
			$n = $e.Current.Name
			if (-not $n) { $n = $e.Current.AutomationId }
			"  $t | $n | id=$($e.Current.AutomationId) | enabled=$($e.Current.IsEnabled)"
			if ($Press -and $n -match $Press -and $t -ne 'Text') {
				$p = $null
				if ($e.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$p)) { $p.Invoke(); "  >>> invoked $n"; exit 0 }
				if ($e.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$p)) { $p.Toggle(); "  >>> toggled $n"; exit 0 }
			}
		}
	}
}
