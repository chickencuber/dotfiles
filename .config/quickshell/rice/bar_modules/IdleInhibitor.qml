import QtQuick
import Quickshell.Wayland
import "../singletons/"

BarIconButton {
    id: root
    IdleInhibitor {
        id: inhibitor
        enabled: false
        window: root.bar
    }
    iconColor: inhibitor.enabled? Theme.accentText: Theme.text
    background: Rectangle {
        color: inhibitor.enabled? Theme.accent: Theme.background
        border.width: 1
        border.color: Theme.accent
        radius: 10
    }
    name: inhibitor.enabled? "visibility": "visibility_off"
    onClicked: {
        inhibitor.enabled = !inhibitor.enabled 
    }
}
