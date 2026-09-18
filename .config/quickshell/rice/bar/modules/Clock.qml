import QtQuick
import Quickshell
import "../.."

Item {
    id: root

    // ───── Configuration ─────

    property string font: "JetBrainsMono Nerd Font Mono"
    property int size: 40
    property int padding: 8

    property color textColor: Theme.text
    signal clicked

    // ───── Time ─────

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm:ss AP")

    // ───── Layout ─────

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

        padding: root.padding
        anchors.fill: parent

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: root.time

            font.family: root.font
            color: root.textColor
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: root.clicked()
    }
}
