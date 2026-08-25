import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons

Scope {
  id: root
  property string state: "idle"
  property var cfg: ({})

  function n(k,d){ return (cfg && cfg[k]!==undefined && cfg[k]!==null) ? cfg[k] : d; }
  function nn(k,d){ var v=Number(n(k,d)); return isFinite(v)?v:d; }

  // Theme-aware colours (use the selected Omarchy accent), config-overridable.
  function colorFor(s){
    if(cfg.colors && cfg.colors[s]) return cfg.colors[s];
    if(s==="working") return Color.accent;
    if(s==="needs")   return (typeof Color.urgent!=="undefined") ? Color.urgent : "#e0af68";
    if(s==="error")   return (typeof Color.urgent!=="undefined") ? Color.urgent : "#f7768e";
    if(s==="done")    return (cfg.doneColor || "#4c8dff");   // solid blue when finished
    return "transparent";
  }
  readonly property color glow: state==="idle" ? "transparent" : colorFor(state)

  readonly property bool pulse: state==="working" || state==="needs" || state==="error"
  readonly property bool solid: state==="done"
  readonly property int period: Math.max(400, (cfg.periods && isFinite(Number(cfg.periods[state]))) ? Number(cfg.periods[state]) : (state==="working"?3400:state==="needs"?1500:1100))
  readonly property int  bw:  Math.max(0, Math.min(24, nn("borderWidth", 4)))
  readonly property int  gw:  Math.max(0, Math.min(160, nn("glowWidth", 26)))
  readonly property real gop: Math.max(0, Math.min(1, nn("glowOpacity", 0.40)))
  readonly property int  rad: Math.max(0, Math.min(48, nn("radius", 16)))
  readonly property bool enabled: n("enabled", true)

  Process {
    id: reader
    command: ["timeout","1","python3","-c","import os,sys,stat\ntry:\n fd=os.open(sys.argv[1],os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)\nexcept OSError:\n sys.exit(0)\ntry:\n st=os.fstat(fd)\n if stat.S_ISREG(st.st_mode): sys.stdout.buffer.write(os.read(fd,int(sys.argv[2])))\nfinally:\n os.close(fd)", Quickshell.env("HOME") + "/.local/state/omarchy/agent-ambient", "256"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { var s=(text||"").trim(); if(s.length) root.state=s; } }
  }
  Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true; onTriggered: if(!reader.running) reader.running = true }

  Process {
    id: cfgReader
    command: ["timeout","1","python3","-c","import os,sys,stat\ntry:\n fd=os.open(sys.argv[1],os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)\nexcept OSError:\n sys.exit(0)\ntry:\n st=os.fstat(fd)\n if stat.S_ISREG(st.st_mode): sys.stdout.buffer.write(os.read(fd,int(sys.argv[2])))\nfinally:\n os.close(fd)", Quickshell.env("HOME") + "/.config/omarchy/ambient-agent.json", "8192"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: { try { var o=JSON.parse(text||"{}"); root.cfg=o; } catch(e) {} } }
  }
  Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if(!cfgReader.running) cfgReader.running = true }

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
        anchors.fill: parent; color:"transparent"; radius: root.rad
        border.width: root.gw; border.color: root.glow
        visible: root.state !== "idle"
        opacity: sharp.opacity * root.gop
        Behavior on border.color { ColorAnimation { duration: 350 } }
      }
      Rectangle {
        id: sharp
        anchors.fill: parent; color:"transparent"; radius: root.rad
        border.width: root.bw; border.color: root.glow
        visible: root.state !== "idle"
        opacity: 1
        Behavior on border.color { ColorAnimation { duration: 350 } }
        // pulse for working/needs/error; done stays solid (no animation)
        SequentialAnimation on opacity {
          running: root.pulse
          loops: Animation.Infinite
          NumberAnimation { from:0.4; to:1.0; duration: root.period/2; easing.type: Easing.InOutSine }
          NumberAnimation { from:1.0; to:0.4; duration: root.period/2; easing.type: Easing.InOutSine }
        }
      }
    }
  }
}
