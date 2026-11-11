# Finds the recording Snipping Tool just made, checks it, and copies it to the destination.
# Snipping Tool writes into its TempState folder first; "Screen Recordings" may or may not get a copy, so look in both,
# pick only files written after -Since, and never move an older file by mistake.
# usage: save-recording.ps1 -Since "2026-11-03 18:13" -Dest "D:\Recordings\UC4-draft.mp4"
param([datetime]$Since, [string]$Dest)
$dirs = @("$env:LOCALAPPDATA\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe\TempState\Recordings", "$env:USERPROFILE\Videos\Screen Recordings")
$f = Get-ChildItem $dirs -Filter *.mp4 -EA 0 | ? { $_.LastWriteTime -gt $Since -and $_.Length -gt 0 } | sort LastWriteTime -Desc | select -First 1
if (-not $f) { "NO RECORDING newer than $Since"; exit 2 }
New-Item -ItemType Directory -Force (Split-Path $Dest) | Out-Null
Copy-Item $f.FullName $Dest
$dur = [double](ffprobe -v error -show_entries format=duration -of csv=p=0 $Dest)
$wall = ($f.LastWriteTime - $Since).TotalSeconds
"saved $Dest  duration=$([math]::Round($dur,1))s  wall-clock=$([math]::Round($wall,1))s  size=$([math]::Round($f.Length/1MB))MB"
# Snipping Tool can silently stop capturing frames; if the video is much shorter than the wall-clock time, say so.
if ($dur -lt $wall * 0.8) { "WARNING: video is $([math]::Round($wall-$dur))s shorter than the time recorded - capture may have frozen. Check the last frame." }
$last = [IO.Path]::ChangeExtension($Dest, ".last.png")
ffmpeg -v error -y -sseof -2 -i $Dest -frames:v 1 -vf scale=960:-1 $last
"last frame: $last"
