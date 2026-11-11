import QtQuick
import Quickshell.Services.UPower
import "../singletons/"
import "../components/"

BarButton {
    id: root

    property int spacing: 7
    property int iconSize: 3

    property color textColor: Theme.text

    property bool showPercentage: true
    property bool showIcon: true

    readonly property var battery: UPower.displayDevice

    readonly property int percentage: Math.round((battery?.percentage ?? 0) * 100)

    readonly property bool charging: battery?.state === UPowerDeviceState.Charging

    readonly property bool pluggedIn: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.FullyCharged

    readonly property string batteryIcon: {
        if (root.percentage >= 100)
            return root.charging | root.pluggedIn ? "battery_charging_full" : "battery_full";

        if (root.charging) {
            if (root.percentage >= 80)
                return "battery_charging_90";
            if (root.percentage >= 60)
                return "battery_charging_80";
            if (root.percentage >= 40)
                return "battery_charging_60";
            if (root.percentage >= 20)
                return "battery_charging_50";
            return "battery_charging_20";
        }

        if (root.percentage >= 80)
            return "battery_6_bar";
        if (root.percentage >= 60)
            return "battery_5_bar";
        if (root.percentage >= 40)
            return "battery_4_bar";
        if (root.percentage >= 20)
            return "battery_3_bar";
        if (root.percentage >= 10)
            return "battery_2_bar";

        return "battery_1_bar";
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

            name: root.batteryIcon
            iconColor: root.textColor
            filled: true
        }
    }
}
