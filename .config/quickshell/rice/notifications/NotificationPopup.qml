import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property var notificationServer
    property var notificationCenter


    anchors.top: true
    anchors.right: true

    margins.top: 8
    margins.right: 8

    implicitWidth: 420
    implicitHeight: popupColumn.implicitHeight

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification_popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    ColumnLayout {
        id: popupColumn

        visible: (!root.notificationCenter?.visible) && (!root.notificationCenter?.dndEnabled)
        width: parent.width
        spacing: 8

        Repeater {
            model: root.notificationServer.trackedNotifications

            delegate: NotificationPopupItem {
                required property var modelData

                Layout.fillWidth: true
                notification: modelData
            }
        }
    }
}
