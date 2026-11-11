pragma ComponentBehavior: Bound
import QtQuick
import "../singletons/"
import "../components/"

Module {
    id: root

    readonly property var wm: ShellContext.wm

    property int name_size: 14
    property int icon_size: 15

    property int spacing: 6
    property int item_spacing: 8

    Rectangle {
        width: row.implicitWidth + 10
        height: root.bar_thickness

        color: Theme.background
        border.width: 1
        border.color: Theme.accent
        radius: 10

        Row {
            id: row

            anchors.centerIn: parent
            spacing: root.item_spacing

            Repeater {
                model: root.wm.workspaces

                delegate: Item {
                    id: workspace

                    required property var modelData

                    property bool hovered: mouseArea.containsMouse
                    property bool active: modelData === root.wm.focusedWorkspace

                    width: content.implicitWidth + 4
                    height: root.bar_thickness

                    Row {
                        id: content

                        anchors.centerIn: parent
                        spacing: root.spacing

                        Text {
                            text: workspace.modelData.name + ":"
                            color: workspace.hovered ? Theme.accent : Theme.text

                            font.family: Theme.font
                            font.pixelSize: root.name_size

                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Icon {
                            width: root.icon_size
                            height: root.icon_size
                            name: workspace.active ? "radio_button_checked" : "radio_button_unchecked"
                            iconColor: workspace.hovered ? Theme.accent : Theme.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: workspace.modelData.activate()
                    }
                }
            }
        }
    }
}
