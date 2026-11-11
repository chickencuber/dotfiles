pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.SystemTray
import "../singletons/"
import "../services/"

Module {
    id: root

    readonly property var window: root.bar

    property int spacing: 8
    property int size: 40
    property int icon_size: 20

    visible: SystemTray.items.values.length > 0

    Rectangle {
        width: row.implicitWidth + 16
        height: root.bar_thickness

        color: Theme.background
        border.color: Theme.accent
        border.width: 1
        radius: 10

        Row {
            id: row

            anchors.centerIn: parent
            spacing: root.spacing

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayItem

                    required property SystemTrayItem modelData

                    width: root.icon_size
                    height: root.icon_size

                    Image {
                        anchors.fill: parent
                        source: trayItem.modelData.icon
                        sourceSize: Qt.size(root.icon_size, root.icon_size)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.text
                        opacity: mouseArea.containsMouse ? 0.15 : 0
                        radius: 4
                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        z: 100
                        hoverEnabled: true

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.MiddleButton |
                            Qt.RightButton

                        onClicked: mouse => {
                            switch (mouse.button) {
                            case Qt.LeftButton:
                                if (trayItem.modelData.onlyMenu) {
                                    if (trayItem.modelData.hasMenu)
                                        ShellContextMenu.openNative(trayItem, trayItem.modelData.menu)
                                } else {
                                    trayItem.modelData.activate()
                                }
                                break

                            case Qt.RightButton:
                                if (trayItem.modelData.hasMenu)
                                    ShellContextMenu.openNative(trayItem, trayItem.modelData.menu)
                                break

                            case Qt.MiddleButton:
                                trayItem.modelData.secondaryActivate()
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}
