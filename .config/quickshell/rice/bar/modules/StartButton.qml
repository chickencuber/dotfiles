import QtQuick.Controls
import QtQuick
import Quickshell
import "../.."

Button {
    property int size: 40
    font.pointSize: 20
    width: size
    height: size
    text: ""
    font.family: "JetBrainsMono Nerd Font Mono"
    background: Rectangle {
        color: Theme.background
        border.width: 1
        border.color: Theme.accent
        radius: 10
    }
    onClicked: {
        Quickshell.execDetached(["qs", "-c", "rice", "ipc", "call", "power", "toggle"])
    }
}
