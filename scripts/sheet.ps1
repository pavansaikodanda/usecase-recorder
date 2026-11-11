# Contact sheet of a recording: one tile every -Every seconds with the timestamp burned in (6 columns x 6 rows per image).
# usage: sheet.ps1 -In rec.mp4 -Every 60 -Out D:\sheets\UC3   -> UC3_01.png, UC3_02.png ...
param([string]$In, [int]$Every = 30, [string]$Out)
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
$vf = "fps=1/$Every,scale=320:-1,drawtext=fontfile='C\:/Windows/Fonts/arialbd.ttf':text='%{pts\:hms}':x=4:y=4:fontsize=18:fontcolor=yellow:box=1:boxcolor=black@0.7,tile=6x6"
ffmpeg -v error -y -threads 2 -i $In -vf $vf -vsync vfr "$($Out)_%02d.png"
Get-ChildItem "$($Out)_*.png" | % FullName
