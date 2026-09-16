import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Scope {
    id: root

    property bool shouldShowOsd: false
    property bool capsEnabled: false

    IpcHandler {
        target: "osd.caps"

        function run(): void {
            // Wait for the lock state to update first.
            readDelay.restart();
        }
    }

    Timer {
        id: readDelay

        interval: 75
        repeat: false

        onTriggered: {
            updateCaps.running = true;
        }
    }

    Process {
        id: updateCaps

        command: ["hyprctl", "devices", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);

                    if (!data.keyboards)
                        return;
                    const keyboard = data.keyboards.find(k => k.main);

                    if (!keyboard)
                        return;
                    root.capsEnabled = keyboard.capsLock;
                    root.shouldShowOsd = true;

                    hideTimer.restart();
                } catch (error) {
                    console.log("Caps OSD error:", error);
                }
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 1000
        repeat: false

        onTriggered: {
            root.shouldShowOsd = false;
        }
    }

    PanelWindow {
        visible: root.shouldShowOsd
        anchors.bottom: true
        margins.bottom: screen.height / 5

        exclusiveZone: 0

        implicitWidth: 140
        implicitHeight: 60

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "caps_osd"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent

            radius: height / 2

            color: Qt.alpha(Theme.background, 0.8)

            border.width: 1
            border.color: Theme.accent

            RowLayout {
                id: row
                anchors.fill: parent

                anchors.leftMargin: 16
                anchors.rightMargin: 16

                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignVCenter

                    text: root.capsEnabled ? "󰪛" : "󰪜"

                    color: Theme.text

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 28
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    text: root.capsEnabled ? "Caps On" : "Caps Off"

                    color: Theme.text

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                }
            }
        }
    }
}
