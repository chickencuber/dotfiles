pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../components/"
import "../services/"
import "../applets/"

Scope {
    id: root

    property bool focus: false
    PanelWindow {
        id: popupWindow

        anchors {
            top: true
            right: true
        }

        margins {
            top: 8
            right: 8
        }

        implicitWidth: 420
        implicitHeight: popupColumn.implicitHeight + 16

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notification_popup"
        WlrLayershell.keyboardFocus: root.focus? WlrKeyboardFocus.OnDemand: WlrKeyboardFocus.None

        ColumnLayout {
            id: popupColumn

            anchors.fill: parent
            visible: !NotificationCenter.visible
                && !NotificationCenter.dndEnabled

            spacing: 8

            Repeater {
                model: NotificationService.trackedNotifications

                delegate: NotificationCard {
                    required property var modelData
                    onExited: root.focus = false
                    onEntered: root.focus = true 

                    Layout.fillWidth: true

                    notification: modelData
                    popupMode: true
                }
            }
        }
    }
}
