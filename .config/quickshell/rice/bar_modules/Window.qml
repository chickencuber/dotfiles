import QtQuick
import Quickshell
import "../singletons"
import "../services/wms"

Module {
    id: root

    readonly property WM wm: ShellContext.wm

    property int max_char: 40
    property int icon_size: 22

    readonly property var activeWindow: wm.focusedWindow
    readonly property string title: activeWindow?.title ?? ""
    readonly property string appId: activeWindow?.wayland?.appId ?? ""
    readonly property var desktopEntry: appId !== "" ? DesktopEntries.byId(appId) : null
    readonly property string iconName: desktopEntry?.icon ?? ""

    Rectangle {

        width: row.implicitWidth + 10
        height: root.bar_thickness

        color: Theme.background
        border.width: 1
        border.color: Theme.accent
        radius: 10

        visible: root.activeWindow !== null && root.activeWindow.workspace === root.wm.focusedWorkspace
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Image {
                width: root.icon_size
                height: root.icon_size
                source: root.iconName !== "" ? ShellContext.iconPath(root.iconName) : ""
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.title.length > root.max_char ? root.title.slice(0, root.max_char - 1) + "…" : root.title

                font.family: Theme.font
                font.pixelSize: 14
                color: Theme.text
            }
        }
    }
}
