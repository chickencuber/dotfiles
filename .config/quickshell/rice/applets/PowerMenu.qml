pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import "../singletons/"
import "../components/"

Scope {
    id: root
    property alias open: powerPanel.open

    property int selectedIndex: 0

    property list<string> options: ["Shut Down", "Reboot", "Lock", "Log Off",]

    function power(): void {
        if (powerProcess.running)
            return;
        powerPanel.open = false;

        switch (root.selectedIndex) {
        case 0:
            powerProcess.command = ["shutdown", "now"];
            break;
        case 1:
            powerProcess.command = ["reboot"];
            break;
        case 2:
            powerProcess.command = ["loginctl", "lock-session"];
            break;
        case 3:
            powerProcess.command = ["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID")];
            break;
        }

        powerProcess.running = true;
    }

    Process {
        id: powerProcess
    }

    FloatingPanel {
        id: powerPanel
        ipc: "power"
        width: optionsColumn.width + 12
        height: optionsColumn.height + 12
        background: "transparent"
        origin: FloatingPanel.Center
        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade
        FocusScope {
            id: kbFocus

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
                powerPanel.open = false;
                event.accepted = true;
            }

            Component.onCompleted: {
                forceActiveFocus();
            }

            Rectangle {
                anchors.fill: parent

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

                                font.family: Theme.font
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
                                    kbFocus.forceActiveFocus();
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
        onAnimationFinished: {
            if (open) {
                Qt.callLater(() => {
                    kbFocus.forceActiveFocus();
                });
            } else {
                root.selectedIndex = 0;
            }
        }
    }
}
