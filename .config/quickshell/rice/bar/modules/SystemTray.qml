import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../.."

Item {
    id: root

    required property var window
    property int spacing: 8
    property int size: 40
    property int icon_size: 24

    implicitWidth: trayRow.implicitWidth
    implicitHeight: size

    visible: SystemTray.items.values.length > 0

    property Component background: Component {
        Rectangle {
            color: Theme.background
            radius: 10
            border.color: Theme.accent
            border.width: 1
        }
    }
    Loader {
        anchors.fill: parent
        sourceComponent: root.background
    }
    Row {
        padding: 8
        id: trayRow
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
                    source: modelData.icon
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
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: mouse => {
                        const mapped = mapToItem(root.window.contentItem, mouse.x, mouse.y);
                        switch (mouse.button) {
                        case Qt.LeftButton:
                            if (modelData.onlyMenu)
                                modelData.display(root.window, mapped.x, mapped.y);
                            else
                                modelData.activate();
                            break;
                        case Qt.RightButton:
                            if (modelData.hasMenu)
                                modelData.display(root.window, mapped.x, mapped.y);
                            break;
                        case Qt.MiddleButton:
                            modelData.secondaryActivate();
                            break;
                        }
                    }
                }
            }
        }
    }
}
