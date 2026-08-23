#!/usr/bin/env bash
# Instala Ambient Agent (plugin del shell de Omarchy + CLI).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# 1) CLI
mkdir -p "$HOME/.local/bin"
install -m755 "$HERE/bin/agent-ambient" "$HOME/.local/bin/agent-ambient"
# 2) plugin (si no usaste 'omarchy plugin add')
mkdir -p "$HOME/.config/omarchy/plugins/ambient-agent"
cp "$HERE/plugin/"* "$HOME/.config/omarchy/plugins/ambient-agent/"
# 3) config (no pisa la tuya si ya existe)
[ -f "$HOME/.config/omarchy/ambient-agent.json" ] || cp "$HERE/ambient-agent.json" "$HOME/.config/omarchy/ambient-agent.json"
# 4) activar
omarchy plugin enable ambient-agent 2>/dev/null || true
omarchy restart shell 2>/dev/null || true
echo "✓ Ambient Agent instalado. Prueba:  agent-ambient working   (y  agent-ambient idle)"
echo "  Integración automática: llama a agent-ambient <estado> desde los hooks de tu agente (ver hooks/example-hooks.json)."
