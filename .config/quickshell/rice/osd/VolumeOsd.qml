import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import ".."

Scope {
    id: root

    property bool shouldShowOsd: false

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property real volume: root.sink?.audio?.volume ?? 0

    readonly property bool muted: root.sink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [root.sink]
    }

    IpcHandler {
        target: "osd.volume"

        function run(): void {
            root.shouldShowOsd = true;
            hideTimer.restart();
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

        Rectangle {
            anchors.fill: parent

            radius: 999

            color: Qt.alpha(Theme.background, 0.8)

            border.width: 1
            border.color: Theme.accent

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 16
                anchors.rightMargin: 16

                spacing: 12

                IconImage {
                    Layout.alignment: Qt.AlignVCenter

                    implicitSize: 30

                    source: root.muted ? Quickshell.iconPath("audio-volume-muted-symbolic") : root.volume <= 0.33 ? Quickshell.iconPath("audio-volume-low-symbolic") : root.volume <= 0.66 ? Quickshell.iconPath("audio-volume-medium-symbolic") : Quickshell.iconPath("audio-volume-high-symbolic")

                    opacity: root.muted ? 0.5 : 1.0
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

                        width: root.muted ? 0 : parent.width * root.volume

                        radius: 999

                        color: Theme.text
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter

                    text: root.muted ? "Muted" : `${Math.round(root.volume * 100)}%`

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16

                    color: Theme.text

                    opacity: root.muted ? 0.5 : 1.0
                }
            }
        }
    }
}
