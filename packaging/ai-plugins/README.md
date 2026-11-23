# AI plugins

`zepp-coach/skills/zepp-coach/SKILL.md` is the coaching skill that goes with the
PaceBridge MCP server: read the data first, advise conservatively, no medical
judgements, draft plans in the `pacebridge-plan/3` format, publish only after the
user agrees.

## What ships where

| Piece | Where |
|---|---|
| `pacebridge-mcp` and `pacebridge-cli` | Bundled as sidecars on Windows, macOS and Linux (`src-tauri/tauri.sidecar.conf.json`, staged by `scripts/release/stage-mcp-sidecar.ps1`), and in the separate `pacebridge-tools` archive for headless use |
| Claude Code plugin | `.claude-plugin/marketplace.json` at the repository root → this directory (`.claude-plugin/plugin.json`) |
| Codex plugin | `.agents/plugins/marketplace.json` at the repository root → this directory (`.codex-plugin/plugin.json`) |
| Claude Desktop | `PaceBridge.mcpb`, written by the app (`save_mcp_bundle`) because its manifest must point at the installed sidecar |

The plugins carry the skill only. The MCP server is registered separately by
the command the app copies, because its path differs on every machine.

## The settings buttons (Settings › AI tools › Connect a local AI)

The commands come from `src/lib/mcpClients.ts`; the plugin marketplace ref is
`main` (`PLUGIN_MARKETPLACE_REF`).

| Client | What the button does |
|---|---|
| Claude Code | Copies `claude mcp add --scope user pacebridge "--" "<path>"`, `claude plugin marketplace add lingcang728/PaceBridge#main`, `claude plugin install zepp-coach@pacebridge` |
| Codex | Copies `codex mcp add pacebridge "--" "<path>"`, `codex plugin marketplace add lingcang728/PaceBridge --ref main`, `codex plugin add zepp-coach@pacebridge` |
| OpenCode | Copies `opencode mcp add --global pacebridge "--" "<path>"` |
| Grok Build | Copies `grok mcp add -s user pacebridge "<path>"` |
| Factory | Copies a `~/.factory/mcp.json` entry |
| Claude Desktop | Asks for a folder, saves `PaceBridge.mcpb` there and shows it in the file manager |

The server reads the whole library by default; with **Only shared tasks** on,
every command adds `--scope task`. When a client is still registered with an
older path or the other scope, Claude Code and Codex get a `mcp remove` line
first. When the library is not the `data` folder next to the executable, the
commands also set `PACEBRIDGE_DATA_DIR`.

Two details matter on Windows: `"--"` is quoted because PowerShell drops a bare
`--` before it reaches the npm-installed `.ps1` shims, and paths are always
double-quoted.
