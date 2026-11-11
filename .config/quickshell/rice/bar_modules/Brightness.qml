import QtQuick
import Quickshell.Io
import "../singletons/"
import "../components/"

BarButton {
    id: root

    property int spacing: 7
    property int iconSize: 3

    property color textColor: Theme.text

    property bool showPercentage: true
    property bool showIcon: true

    property int percentage: 0

    readonly property string brightnessIcon: {
        if (root.percentage <= 10)
            return "brightness_1";
        if (root.percentage <= 20)
            return "brightness_2";
        if (root.percentage <= 30)
            return "brightness_3";
        if (root.percentage <= 40)
            return "brightness_4";
        if (root.percentage <= 50)
            return "brightness_5";
        if (root.percentage <= 60)
            return "brightness_6";

        return "brightness_7";
    }

    contentItem: Row {
        id: row

        anchors.fill: parent
        anchors.margins: 8
        spacing: root.spacing

        Text {
            id: percentageText

            visible: root.showPercentage
            anchors.verticalCenter: parent.verticalCenter

            text: `${root.percentage}%`

            font.family: Theme.font
            color: root.textColor
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showIcon

            width: percentageText.font.pixelSize + root.iconSize
            height: width

            name: root.brightnessIcon
            iconColor: root.textColor
        }
    }

    Process {
        id: brightnessctl

        command: ["brightnessctl", "-m"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",");

                if (parts.length < 4)
                    return;

                const value = parseInt(parts[3].replace("%", ""));

                if (!isNaN(value))
                    root.percentage = value;
            }
        }

        onExited: updateTimer.restart()
    }

    Timer {
        id: updateTimer

        interval: 100
        running: true

        onTriggered: brightnessctl.running = true
    }
}
