import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Scope {
    id: root

    property bool shouldShowOsd: false
    property string title: "Nothing Playing"
    property string artist: ""
    property bool playing: false

    IpcHandler {
        target: "osd.media"

        function run(): void {
            getMedia.running = true
        }
    }

    Process {
        id: getMedia

        command: [
            "playerctl",
            "metadata",
            "--format",
            "{{title}}|{{artist}}|{{status}}"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split("|")

                if (parts.length >= 3) {
                    root.title = parts[0] || "Unknown Title"
                    root.artist = parts[1] || "Unknown Artist"
                    root.playing = parts[2] === "Playing"
                } else {
                    root.title = "Nothing Playing"
                    root.artist = ""
                    root.playing = false
                }

                root.shouldShowOsd = true
                hideTimer.restart()
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.title = "Nothing Playing"
                root.artist = ""
                root.playing = false

                root.shouldShowOsd = true
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 1500

        onTriggered: {
            root.shouldShowOsd = false
        }
    }

    PanelWindow {
        visible: root.shouldShowOsd

        anchors.bottom: true
        margins.bottom: screen.height / 5

        exclusiveZone: 0

        implicitWidth: 300
        implicitHeight: 60

        color: "transparent"

        mask: Region {}

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "media_osd"
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

                    text: root.playing ? "" : ""

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 28

                    color: Theme.text
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    spacing: 0

                    Text {
                        Layout.fillWidth: true

                        text: root.title

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 15
                        font.bold: true

                        color: Theme.text

                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true

                        visible: root.artist !== ""

                        text: root.artist

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 12

                        color: Qt.alpha(Theme.text, 0.6)

                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
