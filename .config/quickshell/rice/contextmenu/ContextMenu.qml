import QtQuick
import Quickshell.Wayland
import Quickshell
import Quickshell.Io
import ".."

PanelWindow {
    id: menu

    property Item target: null
    property var items: []

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            menu.close();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusiveZone: -1
    visible: false

    property int cursorX: 0
    property int cursorY: 0

    property int popupX: {
        var x = cursorX + popupMargin;

        if (x + popupWidth > width)
            x = cursorX - popupWidth - popupMargin;

        return Math.max(8, Math.min(x, width - popupWidth - 8));
    }

    property int popupMargin: 12

    property int popupWidth: rect.implicitWidth
    property int popupHeight: rect.implicitHeight

    property int popupY: {
        var y = cursorY + popupMargin;

        if (y + popupHeight > height)
            y = cursorY - popupHeight - popupMargin;

        return Math.max(8, Math.min(y, height - popupHeight - 8));
    }

    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        id: rect
        implicitWidth: 196
        implicitHeight: menuContent.implicitHeight + 12
        color: Theme.background

        x: menu.popupX
        y: menu.popupY

        Column {
            id: menuContent

            anchors.centerIn: parent

            width: 180
            spacing: 2
            Repeater {
                model: menu.items

                delegate: Item {
                    required property var modelData

                    width: 180
                    height: modelData.separator ? 7 : 32

                    Rectangle {
                        visible: modelData.separator === true

                        anchors.centerIn: parent

                        width: 150
                        height: 1

                        color: Theme.text.alpha(0.1)
                    }

                    Rectangle {
                        visible: modelData.separator !== true

                        anchors.fill: parent

                        radius: 8

                        color: itemMouse.containsMouse ? Theme.accent.alpha(0.18) : "transparent"

                        Text {
                            anchors.fill: parent

                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            verticalAlignment: Text.AlignVCenter

                            text: modelData.text ?? ""
                            color: modelData.color ?? Theme.text

                            font.family: "Hack Nerd Font"
                            font.pixelSize: 12
                            font.bold: true

                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: itemMouse

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (modelData.action)
                                    modelData.action();

                                menu.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // Close when Escape is pressed
    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            menu.close();
        }
    }

    function open(item, menuItems) {
        menu.items = menuItems;
        menu.target = item;
        cursorProcess.running = true;
    }

    Process {
        id: cursorProcess

        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim();

                var parts = value.split(",");

                if (parts.length >= 2) {
                    menu.cursorX = parseInt(parts[0].trim());

                    menu.cursorY = parseInt(parts[1].trim());
                }

                menu.visible = true;
            }
        }
    }

    function close() {
        menu.visible = false;
        menu.target = null;
        menu.items = [];
    }
}
