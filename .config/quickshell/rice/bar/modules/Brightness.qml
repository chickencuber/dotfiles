import QtQuick
import Quickshell
import Quickshell.Io
import "../.."

Item {
    id: root

    property string font: "JetBrainsMono Nerd Font Mono"
    property int size: 40
    property int spacing: 8
    property int iconSize: 8

    property color textColor: Theme.text

    property bool showPercentage: true
    property bool showIcon: true

    property int percentage: 0

    readonly property string backlightIcon: {
        if (root.percentage <= 10)
            return ""
        if (root.percentage <= 20)
            return ""
        if (root.percentage <= 30)
            return ""
        if (root.percentage <= 40)
            return ""
        if (root.percentage <= 50)
            return ""
        if (root.percentage <= 60)
            return ""
        if (root.percentage <= 70)
            return ""
        if (root.percentage <= 85)
            return ""

        return ""
    }

    implicitWidth: row.implicitWidth
    height: root.size

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
        id: row

        padding: 8
        anchors.fill: parent
        spacing: root.spacing

        Text {
            visible: root.showPercentage

            anchors.verticalCenter: parent.verticalCenter

            text: `${root.percentage}%`

            font.family: root.font
            color: root.textColor
        }

        Text {
            visible: root.showIcon

            anchors.verticalCenter: parent.verticalCenter

            text: root.backlightIcon

            font.family: root.font
            font.pixelSize: 16 + root.iconSize

            color: root.textColor
        }
    }

    Process {
        id: brightnessctl

        command: ["brightnessctl", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",")

                if (parts.length < 4)
                    return

                const value = parseInt(
                    parts[3].replace("%", "")
                )

                if (!isNaN(value))
                    root.percentage = value
            }
        }

        onExited: {
            updateTimer.restart()
        }
    }

    Timer {
        id: updateTimer

        interval: 100

        running: true

        onTriggered: {
            brightnessctl.running = true
        }
    }
}
