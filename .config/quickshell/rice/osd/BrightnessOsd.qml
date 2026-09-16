import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Scope {
    id: root

    property bool shouldShowOsd: false
    property real brightness: 0

    readonly property string backlightIcon: {
        const brightness = root.brightness * 100
        if (brightness <= 10)
            return ""
        if (brightness <= 20)
            return ""
        if (brightness <= 30)
            return ""
        if (brightness <= 40)
            return ""
        if (brightness <= 50)
            return ""
        if (brightness <= 60)
            return ""
        if (brightness <= 70)
            return ""
        if (brightness <= 85)
            return ""

        return ""
    }

    IpcHandler {
        target: "osd.brightness"

        function run(): void {
            updateBrightness.running = true;
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    Process {
        id: updateBrightness

        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",");

                if (parts.length < 4)
                    return;
                const value = parseInt(parts[3].replace("%", ""));

                if (!isNaN(value))
                    root.brightness = value / 100;
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 1000

        onTriggered: root.shouldShowOsd = false
    }


        PanelWindow {
            visible: root.shouldShowOsd
            anchors.bottom: true
            margins.bottom: screen.height / 5

            exclusiveZone: 0

            implicitWidth: 400
            implicitHeight: 60

            color: "transparent"

            mask: Region {}

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "brightness_osd"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent

                radius: height / 2

                color: Qt.alpha(Theme.background, 0.8)

                border.width: 1
                border.color: Theme.accent

                RowLayout {
                    anchors.fill: parent

                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    spacing: 12

                    Text {
                        Layout.alignment: Qt.AlignVCenter

                        text: root.backlightIcon

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 28

                        color: Theme.text
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        implicitHeight: 6

                        radius: 999

                        color: Qt.alpha(Theme.text, 0.5)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom

                            width: parent.width * root.brightness

                            radius: 999

                            color: Theme.text
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter

                        text: `${Math.round(root.brightness * 100)}%`

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 16

                        color: Theme.text
                    }
                }
            }
        }
}
