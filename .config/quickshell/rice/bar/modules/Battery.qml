import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../.."

Item {
    id: root


    property string font: "JetBrainsMono Nerd Font Mono"
    property int size: 40
    property int spacing: 8
    property int iconSize: 4

    property color textColor: Theme.text

    property bool showPercentage: true
    property bool showIcon: true

    property int warningLevel: 30
    property int criticalLevel: 15

    property string chargingIcon: ""

    // ───── Battery ─────

    readonly property var battery: UPower.displayDevice

    readonly property int percentage:
        battery?.percentage * 100 ?? 0

    readonly property bool charging:
        battery?.state === UPowerDeviceState.Charging

    readonly property bool pluggedIn:
        battery?.state === UPowerDeviceState.Charging ||
        battery?.state === UPowerDeviceState.FullyCharged

    // ───── Icon ─────

    readonly property string batteryIcon: {
        if ((root.charging || root.pluggedIn) && root.percentage !== 100)
            return root.chargingIcon

        if (root.percentage >= 80)
            return ""

        if (root.percentage >= 60)
            return ""

        if (root.percentage >= 40)
            return ""

        if (root.percentage >= 20)
            return ""

        return ""
    }

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

        padding: 8
        anchors.fill: parent
        spacing: root.spacing

        Text {
            id: text
            visible: root.showPercentage

            anchors.verticalCenter: parent.verticalCenter

            text: `${root.percentage}%`

            font.family: root.font
            color: root.textColor
        }

        Text {
            visible: root.showIcon

            anchors.verticalCenter: parent.verticalCenter

            text: root.batteryIcon

            font.family: root.font
            font.pixelSize: text.font.pixelSize + root.iconSize
            color: root.textColor
        }
    }
}
