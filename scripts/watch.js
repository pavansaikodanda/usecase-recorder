// Watches the NEWEST task of a Cline-style coding agent (Cline, Roo Code and their forks keep
// <globalStorage>/<extension id>/tasks/<id>/ui_messages.json), so subtasks are followed automatically,
// and exits when a person is needed:
//   ASK <taskId> <kind> <text>   - an approval, a followup question, or completion_result
//   STALL <taskId> <secs>        - stuck on api_req_retry_delayed for > 60 s (cancel, then Resume Task)
//   IDLE <taskId> <secs>         - nothing new for 10 min
// usage: node watch.js <tasks dir>      (or set UCR_TASKS)
//   e.g. %APPDATA%\Code\User\globalStorage\<publisher.extension>\tasks
const fs = require("fs"), path = require("path")
const dir = process.argv[2] || process.env.UCR_TASKS
if (!dir || !fs.existsSync(dir)) { console.error("Pass the agent's tasks folder (or set UCR_TASKS)"); process.exit(2) }
const tick = () => {
	const t = fs.readdirSync(dir).map((n) => ({ n, m: fs.statSync(path.join(dir, n)).mtimeMs })).sort((a, b) => b.m - a.m)[0].n
	let m
	try { m = JSON.parse(fs.readFileSync(path.join(dir, t, "ui_messages.json"), "utf8")) } catch { return setTimeout(tick, 3000) }
	const l = m[m.length - 1], idle = (Date.now() - l.ts) / 1000
	if (l.say === "api_req_retry_delayed" && idle > 60) { console.log("STALL", t, Math.round(idle) + "s"); process.exit(0) }
	if (l.type === "ask" && !l.partial && l.ask !== "command_output" && idle > 5) { console.log("ASK", t, l.ask, (l.text || "").slice(0, 3000)); process.exit(0) }
	if (idle > 600) { console.log("IDLE", t, Math.round(idle) + "s", l.type, l.ask || l.say); process.exit(0) }
	setTimeout(tick, 5000)
}
tick()
