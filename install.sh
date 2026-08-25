#!/usr/bin/env bash
# Installs Ambient Agent: the plugin (if not added via `omarchy plugin add`),
# the agent-ambient CLI, and a default config. Explicit, idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGDIR="$HOME/.config/omarchy/plugins/ambient-agent"
mkdir -p "$PLUGDIR" "$HOME/.local/bin" "$HOME/.config/omarchy" "$HOME/.local/state/omarchy"
cp "$HERE/manifest.json" "$HERE/Service.qml" "$PLUGDIR/"
install -m755 "$HERE/bin/agent-ambient" "$HOME/.local/bin/agent-ambient"
# don't clobber an existing config
[ -f "$HOME/.config/omarchy/ambient-agent.json" ] || cp "$HERE/ambient-agent.json" "$HOME/.config/omarchy/ambient-agent.json"
omarchy plugin enable ambient-agent 2>/dev/null || true
omarchy restart shell 2>/dev/null || true
echo "✓ Ambient Agent installed. Try:  agent-ambient working   (then  agent-ambient idle)"
echo "  Wire it to your agent's hooks — see hooks/example-hooks.json."
