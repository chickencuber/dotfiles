import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.."

Rectangle {
    id: rect
    property int size: 40
    property int max_char: 40
    property int icon_size: 22
    width: row.implicitWidth + 10
    height: size
    color: Theme.background
    border.width: 1
    border.color: Theme.accent
    radius: 10

    visible: Hyprland.activeToplevel !== null && Hyprland.activeToplevel.workspace === Hyprland.focusedWorkspace
    Item {
        id: root
        anchors.centerIn: parent

        width: row.implicitWidth
        height: rect.icon_size

        property var activeWindow: Hyprland.activeToplevel

        property string title: activeWindow?.title ?? ""

        property string appId: activeWindow?.wayland?.appId ?? ""

        property var desktopEntry: appId !== "" ? DesktopEntries.byId(appId) : null

        property string iconName: desktopEntry?.icon ?? ""

        Row {
            id: row
            anchors.fill: parent
            padding: 2
            spacing: 8

            Image {
                width: rect.icon_size
                height: rect.icon_size

                source: root.iconName !== "" ? Quickshell.iconPath(root.iconName) : ""

                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.title.length > rect.max_char ? root.title.slice(0, rect.max_char-1) + "…" : root.title
                font.family: "JetBrainsMono Nerd Font Mono"

                color: Theme.text
                font.pixelSize: 14
            }
        }
    }
}
