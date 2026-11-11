# usecase-recorder

An agent skill that builds a Salesforce use case live with an AI coding agent in a VS Code-based IDE and records it end to end with the Windows Snipping Tool. When the build finishes, it shows the results in a clean Chrome window, saves the unedited draft, and returns the file path with a cut list.

See [SKILL.md](SKILL.md) for the workflow. The helper scripts are in [scripts/](scripts/).

**Requirements:** Windows with a 1920x1080 screen, Node, ffmpeg and ffprobe, and the Salesforce CLI (`sf`).

**Install:** copy this folder into your skills directory (for example `~/.claude/skills/usecase-recorder`), or zip it and upload it as a skill.
