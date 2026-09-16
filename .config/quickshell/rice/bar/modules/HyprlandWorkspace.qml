import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.."

Rectangle {
    id: root

    property int size: 40
    property int name_size: 14
    property int icon_size: 22
    property int spacing: 6
    property int item_spacing: 8

    width: row.implicitWidth + 10
    height: size

    color: Theme.background

    border.width: 1
    border.color: Theme.accent

    radius: 10

    Row {
        id: row

        anchors.centerIn: parent
        spacing: root.item_spacing

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: workspace

                required property var modelData

                property bool hovered: mouseArea.containsMouse
                property bool active: modelData === Hyprland.focusedWorkspace

                width: content.implicitWidth
                height: root.size

                Row {
                    id: content
                    padding: 2

                    anchors.centerIn: parent
                    spacing: root.spacing

                    Text {
                        text: workspace.modelData.name + ":"

                        color: workspace.hovered ? Theme.accent : Theme.text

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: root.name_size

                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: workspace.active ? "" : ""

                        color: workspace.hovered ? Theme.accent : Theme.text

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: root.icon_size

                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        workspace.modelData.activate();
                    }
                }
            }
        }
    }
}
