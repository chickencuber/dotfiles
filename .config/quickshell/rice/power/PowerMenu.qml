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

    property list<string> options: ["Shut Down", "Reboot", "Lock", "Log Off",]

    function power(): void {
        if (root.running)
            return;
        root.running = true;
        powerPanel.visible = false;

        switch (root.selectedIndex) {
        case 0:
            powerProcess.command = ["shutdown", "now"];
            break;
        case 1:
            powerProcess.command = ["reboot"];
            break;
        case 2:
            powerProcess.command = ["hyprlock"];
            break;
        case 3:
            powerProcess.command = ["hyprctl", "dispatch", "hl.dsp.exit()"];
            break;
        }

        powerProcess.running = true;
    }

    property bool running: false

    IpcHandler {
        target: "power"

        function toggle(): void {
            powerPanel.visible = !powerPanel.visible;

            if (powerPanel.visible) {
                root.selectedIndex = 0;

                Qt.callLater(() => {
                    keyboardFocus.forceActiveFocus();
                });
            }
        }
    }

    Process {
        id: powerProcess

        onExited: {
            root.running = false;
        }
    }

    PanelWindow {
        id: powerPanel
        MouseArea {
            anchors.fill: parent
            onClicked: powerPanel.visible = false
        }

        visible: false
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color: "transparent"

        FocusScope {
            id: keyboardFocus

            anchors.fill: parent
            focus: true

            Keys.onUpPressed: event => {
                root.selectedIndex = (root.selectedIndex - 1 + root.options.length) % root.options.length;

                event.accepted = true;
            }

            Keys.onDownPressed: event => {
                root.selectedIndex = (root.selectedIndex + 1) % root.options.length;

                event.accepted = true;
            }

            Keys.onReturnPressed: event => {
                root.power();
                event.accepted = true;
            }

            Keys.onEscapePressed: event => {
                powerPanel.visible = false;
                event.accepted = true;
            }

            Component.onCompleted: {
                forceActiveFocus();
            }

            Rectangle {
                anchors.centerIn: parent

                width: optionsColumn.width + 12
                height: optionsColumn.height + 12

                radius: 12

                color: Theme.background.alpha(0.96)
                border.width: 2
                border.color: Theme.accent

                Column {
                    id: optionsColumn

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
                                font.pixelSize: 15
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
                                    root.power();
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
