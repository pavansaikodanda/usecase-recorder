---
name: usecase-recorder
description: Build a Salesforce use case live with an AI coding agent in a VS Code-based IDE and screen-record it end to end with the Windows Snipping Tool, driving the IDE on the person's desktop and showing the results in a clean Chrome window, then save the unedited draft and return its path. Use when the person gives a use case to "build and record", "record a demo of the agent building X", or asks for a draft recording of an agent-driven Salesforce build (org health check, Agentforce agent, Revenue Cloud setup, PO to quote, etc.).
---

# Use case recorder

Turn a use case into a real build by an AI coding agent (a Cline-style extension in VS Code or a VS Code-based IDE), recorded as an unedited draft (full screen, Snipping Tool), ending with the results shown in Salesforce. Deliver: the saved file path, its length, what is on it, and a cut list of moments the editor must remove.

If the person has naming rules for the product or the model (how to say the product's name, what to call the model in a video), follow them in everything written or spoken for an audience, and add any model/provider name they want hidden to the cut list.

Scripts are in `scripts/` next to this file (call them with the full path). They assume Windows, a 1920x1080 primary screen, the IDE maximized, Node, ffmpeg/ffprobe and the Salesforce CLI (`sf`) on PATH. Set `UCR_WINDOW` to a regex for the IDE window title (or pass `-Match`) and `UCR_TASKS` to the agent's tasks folder.

| Script | Does |
|---|---|
| `win.ps1 -Match <title regex> -Do info/raise/max/click/keys/paste/close [-Shot png]` | Acts on one window only; waits for 4 s of user idle before taking focus, refuses otherwise |
| `scr.ps1 -Do record/click/drag/wheel [-Shot png]` | Full-screen actions; `record` = Win+Shift+R |
| `snip.ps1 -Press "Start recording"` / `-Press "^Stop"` | Snipping Tool buttons via UI Automation |
| `clickblue.ps1` | Presses the IDE's primary blue button once (Run Command / Save / Approve) |
| `watch.js <tasks dir>` | Waits on the agent's newest task; prints `ASK`, `STALL` or `IDLE` |
| `org-window.ps1 -Org <alias> -Path <url path>` / `-Close` | Clean Chrome app window signed in via `sf org open --url-only` |
| `save-recording.ps1 -Since <time> -Dest <file>` | Finds, verifies and copies the new recording; warns if capture froze |
| `sheet.ps1 -In <mp4> -Every <s> -Out <prefix>` | Timestamped contact sheet for building the cut list |

## 1. Prepare (before recording, no screen changes)
1. **Confirm the target.** Find the IDE window (`win.ps1 -Do info`), read the project's `.sf/config.json` target-org and the status-bar org in a screenshot. Ask the person once which window/org to use if anything is ambiguous. Never use a client's window or org they did not name.
2. **Read-only readiness check** with plain `sf` queries: the objects/features the use case needs exist and are enabled (e.g. Agentforce: `EinsteinGpt`, `AgentPlatform`, `Bot` settings via a metadata retrieve; Quotes: `Quote.settings`), the data it will touch, and whether the org is production. If a feature is off and turning it on needs terms acceptance, stop and ask; do not enable it yourself.
3. **Write the prompt** for the agent (save to a file): the goal in plain words, then rules: use only org alias X; run each `sf` command on its own (no chaining); never delete anything; read-only first and ask before fixing (for health checks); only claim what a query or real result shows; finish by opening the result in Salesforce. Keep it short so it reads well on camera.
4. **Prepare inputs** the use case needs inside the project folder (e.g. a fictional customer PO PDF rendered from HTML with Playwright). Fictional people only, `.example` emails.
5. Check free RAM (`Win32_OperatingSystem.FreePhysicalMemory`); close the demo Chrome profile if open. Under ~2 GB free, render nothing in parallel.

## 2. Record
1. `win.ps1 -Do raise`, then `scr.ps1 -Do record`, wait 3 s, `scr.ps1 -Do drag -X 1 -Y 1 -X2 1919 -Y2 1019`, `snip.ps1 -Press "Start recording"`. Note the start time for `save-recording.ps1 -Since`.
2. Start a new agent session if not on its home screen; click the prompt box, `win.ps1 -Do paste -Text <prompt>` (strip `\r`), screenshot to check, then click send.
3. Run `node watch.js <tasks dir>` in the background and act on each result:
   - **ASK command / tool**: read the exact command. Approve with `clickblue.ps1` only if it is read-only or is the change the person asked for. Then hide the terminal panel so the recording stays on the agent.
   - **ASK followup**: answer with the safest option that moves the demo forward (see 2.1). Type the answer in the message box when the options are long; screenshot first.
   - **STALL** (retry loop, e.g. HTTP 502 stream stall): click **Cancel**, then **Resume Task**, immediately. If it stalls again, cancel and start a new session with a short prompt for only the remaining work (a fresh session also has a small context).
   - **completion_result**: read the agent's summary; check each claim with a query before repeating it.
   - The agent may split work into a **subtask** (new task id); `watch.js` follows the newest task automatically.
   - `win.ps1` exit 3 means the person is using the machine: wait, do not force focus, and re-check whether they already answered.
4. **Show the result in Salesforce** (the audience-facing part): `org-window.ps1 -Org <alias> -Path <record or setup path>`, dismiss Chrome's notification prompt with **Block**, hold each page 4-6 s, scroll slowly with `scr.ps1 -Do wheel`, open related lists, and run a live test in the UI when there is one (e.g. type a request into Agentforce Builder's preview and wait for the answer). For a new page, launch another app window (session cookies persist while the profile is open); closing every window of the profile signs it out, so re-open through `org-window.ps1`. **Never type a password on a login page.**
5. Stop: `snip.ps1 -Press "^Stop"`, wait ~30 s, `save-recording.ps1 -Since <start> -Dest <folder>\<UCn>-<name>-draft.mp4`, then close the Snipping Tool window (`win.ps1 -Match '^Snipping Tool$' -Do close`) and the demo profile (`org-window.ps1 -Close`).
6. **Verify**: open the `.last.png` it writes; if the warning says capture froze or the last frame is not the final Salesforce screen, re-record only the missing part as a second file (`<UCn>b-...`) rather than redoing everything.

### 2.1 Answer policy when the agent asks
- Approve: read-only commands, creating a scratch folder, saving the files it was asked to write, additive data (new records, new active price entries in the needed currency), deactivating (not deleting) clearly stray records.
- Prefer: options that avoid metadata changes to existing shared config (e.g. use an existing picklist value plus a note over adding a new value), and creating new named components over modifying existing ones.
- Decline: deletes, changes to org-wide defaults, anything touching records the use case didn't name. Production orgs need the person's yes for deploys.
- If you can't tell, pause and ask the person in chat; the recording can keep running.

## 3. Report to the person
- Path, length, size of each file; one line on what each part shows.
- **Cut list** with timestamps (build it from `sheet.ps1`): personal pop-ups (Teams/Slack names), any window that isn't the IDE or the clean Chrome window, error text that shows a model or provider name the person wants hidden, long idle stretches.
- Records the demo left in the org (so they can be reused or cleaned), and anything that is not proven (say it plainly, e.g. "coverage rose to 68%, still below 75%").

## 4. Rules that came from real runs
- Act only on the named IDE window and the clean Chrome profile. Bringing "any Chrome window" forward once put a client's org on camera; match exact titles.
- Don't `ShowWindow(SW_RESTORE)` a maximized window (it un-maximizes it and clicks miss); restore only minimized windows.
- The window title changes when an editor tab opens; match on a stable suffix (project or product name), not the full title.
- No autonomous approve-everything loop. Every approval is one reviewed click.
- Don't write files a subagent said it was blocked from writing; don't use API keys from the person's settings.
- Several parallel ffmpeg decodes of 1080p can exhaust RAM; run them one at a time with `-threads 2`.
- Never move a recording you haven't identified by time; Snipping Tool keeps the live file in TempState.

For the branded explainer film made from these recordings, use the `cinematic-usecase-recorded-video` skill.
