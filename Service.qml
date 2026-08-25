import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
  id: root
  property string state: "idle"
  property var cfg: ({})

  function defColor(s){
    if(s==="working") return "#7dcfff";
    if(s==="needs")   return "#e0af68";
    if(s==="done")    return "#9ece6a";
    if(s==="error")   return "#f7768e";
    return "transparent";
  }
  function defPeriod(s){ return s==="working" ? 3800 : (s==="needs" ? 1500 : 1100); }
  function n(k,d){ return (cfg && cfg[k]!==undefined && cfg[k]!==null) ? cfg[k] : d; }

  readonly property bool animate: state === "working" || state === "needs" || state === "error"
  readonly property int  period: (cfg.periods && cfg.periods[state]) ? cfg.periods[state] : defPeriod(state)
  readonly property color glow:  state === "idle" ? "transparent"
                                  : ((cfg.colors && cfg.colors[state]) ? cfg.colors[state] : defColor(state))
  readonly property int   bw:    n("borderWidth", 3)
  readonly property int   gw:    n("glowWidth", 26)
  readonly property real  gop:   n("glowOpacity", 0.40)
  readonly property int   rad:   n("radius", 16)
  readonly property bool  enabled: n("enabled", true)


  // Auto-instalación en el primer arranque: CLI + config + fichero de estado.
  // Hace que `omarchy plugin add ... --enable` sea suficiente (sin clonar ni install.sh).
  Process {
    id: bootstrap
    running: true
    command: ["bash","-lc",
      "D=\"$HOME/.config/omarchy/plugins/ambient-agent\"; " +
      "mkdir -p \"$HOME/.local/state/omarchy\" \"$HOME/.local/bin\" \"$HOME/.config/omarchy\"; " +
      "[ -f \"$HOME/.local/state/omarchy/agent-ambient\" ] || printf idle > \"$HOME/.local/state/omarchy/agent-ambient\"; " +
      "[ -f \"$D/bin/agent-ambient\" ] && install -m755 \"$D/bin/agent-ambient\" \"$HOME/.local/bin/agent-ambient\"; " +
      "[ -f \"$HOME/.config/omarchy/ambient-agent.json\" ] || cp \"$D/ambient-agent.json\" \"$HOME/.config/omarchy/ambient-agent.json\" 2>/dev/null; " +
      "true"]
  }

  // state file — bounded, safe read: regular file only (no symlink/FIFO/device),
  // 256-byte ceiling, 1s deadline. Cannot exhaust or block the shared shell.
  Process {
    id: reader
    command: ["timeout","1","python3","-c","import os,sys,stat\ntry:\n fd=os.open(sys.argv[1],os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)\nexcept OSError:\n sys.exit(0)\ntry:\n st=os.fstat(fd)\n if stat.S_ISREG(st.st_mode): sys.stdout.buffer.write(os.read(fd,int(sys.argv[2])))\nfinally:\n os.close(fd)", Quickshell.env("HOME") + "/.local/state/omarchy/agent-ambient", "256"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { var s=(text||"").trim(); if(s.length) root.state=s; } }
  }
  Timer { interval: 300; running: true; repeat: true; triggeredOnStart: true; onTriggered: if(!reader.running) reader.running = true }

  // config file (hot-reload) — bounded, safe read: regular file only, 8 KB ceiling,
  // 1s deadline. Oversized or malformed input simply falls back to defaults.
  Process {
    id: cfgReader
    command: ["timeout","1","python3","-c","import os,sys,stat\ntry:\n fd=os.open(sys.argv[1],os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)\nexcept OSError:\n sys.exit(0)\ntry:\n st=os.fstat(fd)\n if stat.S_ISREG(st.st_mode): sys.stdout.buffer.write(os.read(fd,int(sys.argv[2])))\nfinally:\n os.close(fd)", Quickshell.env("HOME") + "/.config/omarchy/ambient-agent.json", "8192"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { var o=JSON.parse(text||"{}"); root.cfg=o; } catch(e) {} } }
  }
  Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if(!cfgReader.running) cfgReader.running = true }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.enabled
      color: "transparent"
      WlrLayershell.namespace: "ambient-agent"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        color: "transparent"; radius: root.rad
        border.width: root.gw; border.color: root.glow
        visible: root.state !== "idle"
        opacity: root.state === "idle" ? 0 : glowRect.opacity * root.gop
        Behavior on border.color { ColorAnimation { duration: 400 } }
      }
      Rectangle {
        id: glowRect
        anchors.fill: parent
        color: "transparent"; radius: root.rad
        border.width: root.bw; border.color: root.glow
        visible: root.state !== "idle"
        opacity: root.state === "idle" ? 0 : 1
        Behavior on border.color { ColorAnimation { duration: 400 } }
        SequentialAnimation on opacity {
          running: root.animate
          loops: Animation.Infinite
          NumberAnimation { from: 0.35; to: 1.0; duration: root.period/2; easing.type: Easing.InOutSine }
          NumberAnimation { from: 1.0; to: 0.35; duration: root.period/2; easing.type: Easing.InOutSine }
        }
      }
    }
  }
}
