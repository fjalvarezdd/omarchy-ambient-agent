# Ambient Agent 🫧

**Your Omarchy desktop feels what your AI agents are doing — no pop-ups.**

The screen edge *breathes* cyan while an agent works, warms to amber the moment one **needs your call**, and gives a quiet green pulse when it's done. Peripheral awareness, not interruption.

> `omarchy.agents` shows agent *usage and limits*. Ambient Agent shows the thing that actually costs you time when you run several agents at once: **which one is silently waiting for you.**

![demo](demo.gif)

## Install

```bash
# 1) the Quickshell plugin
omarchy plugin add https://github.com/fjalvarezdd/omarchy-ambient-agent --enable
# 2) the CLI + hooks
git clone https://github.com/fjalvarezdd/omarchy-ambient-agent
cd omarchy-ambient-agent && ./install.sh
```

## Use it

```bash
agent-ambient working   # slow cyan breathing
agent-ambient needs     # amber pulse — an agent is blocked on you
agent-ambient done      # green flash, then calm
agent-ambient error     # red pulse
agent-ambient idle      # off
```

Wrap any long task:

```bash
agent-ambient working; npm run build; agent-ambient done
```

## Make it automatic (Claude Code)

Copy `hooks/claude-code.json` into `~/.claude/settings.json` and the edge reacts on its own:
prompt submitted → **working**, waiting for your input → **needs you**, finished → **done**.
Works the same for Codex/Orca — just call `agent-ambient <state>` from their hooks.

## How it works

A tiny Quickshell layer-shell overlay (transparent, click-through, `WlrLayer.Overlay`) draws the edge glow, driven by a one-word state file at `~/.local/state/omarchy/agent-ambient`. That's it. No daemon, no dependencies beyond Omarchy's shell.

| State | Color | Motion |
|-------|-------|--------|
| working | cyan `#7dcfff` | breathe 3.8s |
| needs you | amber `#e0af68` | pulse 1.5s |
| done | green `#9ece6a` | flash once |
| error | red `#f7768e` | pulse 1.1s |
| idle | — | off |

## Roadmap
- Per-agent orbs in the bar (N agents), edge shows the most urgent state.
- Soft blur glow (MultiEffect) and per-edge direction hints.
- Ships as `<yourname>.ambient-agent` after cloning for local edits.

MIT · built on [Omarchy](https://omarchy.org).

## Configure it

Edit `~/.config/omarchy/ambient-agent.json` (hot-reloads, no restart):

```json
{
  "enabled": true,
  "borderWidth": 3,
  "glowWidth": 26,
  "glowOpacity": 0.40,
  "radius": 16,
  "colors": { "working": "#7dcfff", "needs": "#e0af68", "done": "#9ece6a", "error": "#f7768e" },
  "periods": { "working": 3800, "needs": 1500, "error": 1100 },
  "doneTimeoutMs": 2500
}
```

Match your theme by changing `colors`; calm it down with a smaller `glowWidth`/`glowOpacity`; slow the breathing with bigger `periods`. Set `"enabled": false` to switch it off without uninstalling.
