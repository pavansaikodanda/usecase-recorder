# Opens a Salesforce page in a CLEAN, isolated Chrome app window (own profile, no tabs, no address bar), signed in
# through the Salesforce CLI session link, so no password is typed and none of the person's own tabs appear on camera.
# usage: org-window.ps1 -Org <alias> -Path "/lightning/r/Quote/<id>/view" [-Profile <dir>] [-Close]
#   -Close kills only the processes of this profile (frees memory at the end).
param([string]$Org, [string]$Path = "/lightning/page/home", [string]$Profile = "$env:TEMP\usecase-demo-chrome", [switch]$Close)
if ($Close) { Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" | ? { $_.CommandLine -match [regex]::Escape($Profile) } | % { Stop-Process -Id $_.ProcessId -Force -EA 0 }; "closed demo profile"; exit 0 }
$env:Path += ";$env:APPDATA\npm"
$u = (sf org open -o $Org --path $Path --url-only --json | ConvertFrom-Json).result.url
if (-not $u) { "NO URL from sf org open"; exit 2 }
$chrome = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(default)'
Start-Process $chrome -ArgumentList "--user-data-dir=`"$Profile`"", "--no-first-run", "--start-maximized", "--app=$u"
"opened $Path in clean window"
