import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property string screenshotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    property string font: "JetBrainsMono Nerd Font Mono"

    property int selectedIndex: 0

    property list<string> options: ["Active Monitor", "Active Window", "Monitor", "Window", "Region"]

    property bool running: false

    IpcHandler {
        target: "screenshot"

        function toggle(): void {
            screenshotPanel.visible = !screenshotPanel.visible;

            if (screenshotPanel.visible) {
                root.selectedIndex = 0;

                Qt.callLater(() => {
                    keyboardFocus.forceActiveFocus();
                });
            }
        }
    }

    function takeScreenshot(): void {
        if (root.running)
            return;
        root.running = true;
        screenshotPanel.visible = false;

        switch (root.selectedIndex) {
        case 0:
            screenshotProcess.command = ["hyprshot", "-m", "active", "--mode", "output", "-o", root.screenshotDir];
            break;
        case 1:
            screenshotProcess.command = ["hyprshot", "-m", "active", "--mode", "window", "-o", root.screenshotDir];
            break;
        case 2:
            screenshotProcess.command = ["hyprshot", "-m", "output", "-o", root.screenshotDir];
            break;
        case 3:
            screenshotProcess.command = ["hyprshot", "-m", "window", "-o", root.screenshotDir];
            break;
        case 4:
            screenshotProcess.command = ["hyprshot", "-m", "region", "-o", root.screenshotDir];
            break;
        }

        screenshotDelay.start()
    }
    Timer {
        id: screenshotDelay

        interval: 100
        repeat: false

        onTriggered: {
            screenshotProcess.running = true;
        }
    }

    Process {
        id: screenshotProcess

        onExited: {
            root.running = false;
        }
    }

    PanelWindow {
        id: screenshotPanel
        MouseArea {
            anchors.fill: parent
            onClicked: screenshotPanel.visible = false
        }

        visible: false

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        implicitHeight: 70

        color: "transparent"

        FocusScope {
            id: keyboardFocus

            anchors.fill: parent
            focus: true

            Keys.onLeftPressed: event => {
                root.selectedIndex = (root.selectedIndex - 1 + root.options.length) % root.options.length;

                event.accepted = true;
            }

            Keys.onRightPressed: event => {
                root.selectedIndex = (root.selectedIndex + 1) % root.options.length;

                event.accepted = true;
            }

            Keys.onReturnPressed: event => {
                root.takeScreenshot();
                event.accepted = true;
            }

            Keys.onEscapePressed: event => {
                screenshotPanel.visible = false;
                event.accepted = true;
            }

            Component.onCompleted: {
                forceActiveFocus();
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 70
                color: "transparent"
                Rectangle {
                    anchors.centerIn: parent

                    width: optionsRow.width + 12
                    height: 42

                    radius: height / 2

                    color: Theme.background.alpha(0.96)
                    border.width: 2
                    border.color: Theme.accent

                    Row {
                        id: optionsRow

                        anchors.centerIn: parent

                        spacing: 2

                        Repeater {
                            model: root.options

                            delegate: Rectangle {
                                required property int index
                                required property string modelData

                                width: optionText.width + 24
                                height: 32

                                radius: 16

                                color: "transparent"

                                Text {
                                    id: optionText

                                    anchors.centerIn: parent

                                    text: modelData

                                    color: index === root.selectedIndex ? Theme.accent : Theme.text

                                    font.family: root.font
                                    font.pixelSize: 16
                                    font.bold: index === root.selectedIndex

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {
                                        root.selectedIndex = index;
                                        keyboardFocus.forceActiveFocus();
                                    }

                                    onDoubleClicked: {
                                        root.selectedIndex = index;
                                        root.takeScreenshot();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    keyboardFocus.forceActiveFocus();
                });
            }
        }
    }
}
