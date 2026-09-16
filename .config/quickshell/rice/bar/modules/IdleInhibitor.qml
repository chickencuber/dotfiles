import QtQuick.Controls
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."
Button {
    id: root
    property int size: 40
    property string activated: ""
    property string deactivated: ""
    required property PanelWindow window
    readonly property alias active: inhibitor.enabled
     
    IdleInhibitor {
        id: inhibitor
        enabled: false
        window: root.window
    }
    font.pointSize: 20
    width: size
    height: size
    text: active? activated: deactivated 
    font.family: "JetBrainsMono Nerd Font Mono"
    palette.buttonText: root.active? Theme.accentText: Theme.text
    background: Rectangle {
        color: root.active? Theme.accent: Theme.background
        border.width: 1
        border.color: Theme.accent
        radius: 10
    }
    onClicked: {
        inhibitor.enabled = !inhibitor.enabled 
    }
}
