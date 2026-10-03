import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../.."

Item {
    id: root

    required property var appLists
    required property var tooltip
    required property var contextMenu

    property string mode: "pinned"

    property int spacing: 6
    property int size: 40
    property int icon_size: 22

    property int horizontalPadding: 12
    property int verticalPadding: 6

    property int itemHorizontalPadding: 10
    property int itemSpacing: 4

    property var apps: {
        if (root.mode === "open")
            return ToplevelManager.toplevels;

        if (root.mode === "recent")
            return root.appLists.recentApps;

        return root.appLists.pinnedApps;
    }

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

    implicitWidth: appRow.implicitWidth + root.horizontalPadding * 2
    implicitHeight: root.size + root.verticalPadding * 2

    function iconPath(name: string, check: bool): string {
        if (name === "")
            return "";

        const themed = Quickshell.iconPath(name, true);

        if (themed !== "")
            return themed;

        return Quickshell.iconPath(Quickshell.env("HOME") + "/.local/share/icons/" + name + ".png", check);
    }

    function launchApp(entry): void {
        if (!entry)
            return;

        root.appLists.addRecent(entry.id);

        if (entry.runInTerminal) {
            Quickshell.execDetached(["xdg-terminal-exec", "--", ...entry.command]);
        } else {
            entry.execute();
        }
    }

    function openContextMenu(appItem): void {
        if (root.mode === "open") {
            const toplevel = appItem.toplevel;

            if (!toplevel)
                return;

            const entry = DesktopEntries.byId(toplevel.appId);

            const items = [
                {
                    text: "Focus",
                    action: function () {
                        root.contextMenu.close();

                        Qt.callLater(() => {
                            toplevel.activate();
                        });
                    }
                }
            ];

            if (entry && entry.actions && entry.actions.length > 0) {
                items.push({
                    separator: true
                });

                for (const desktopAction of entry.actions) {
                    items.push({
                        text: desktopAction.name,
                        action: function () {
                            desktopAction.execute();
                        }
                    });
                }
            }

            items.push({
                separator: true
            });

            items.push({
                text: "Close",
                action: function () {
                    toplevel.close();
                }
            });

            const text = root.appLists.isPinned(entry.id) ? "Unpin from Dock" : "Pin to Dock";

            items.push({
                text: text,
                action: function () {
                    root.appLists.togglePin(entry.id);
                }
            });

            root.contextMenu.open(appItem, items);
            return;
        }
        const entry = appItem.entry;

        if (!entry)
            return;

        const items = [
            {
                text: "Open",
                action: function () {
                    root.launchApp(entry);
                }
            }
        ];

        if (entry.actions && entry.actions.length > 0) {
            items.push({
                separator: true
            });

            for (const desktopAction of entry.actions) {
                items.push({
                    text: desktopAction.name,
                    action: function () {
                        desktopAction.execute();
                    }
                });
            }
        }

        items.push({
            separator: true
        });

        const text = root.appLists.isPinned(entry.id) ? "Unpin from Dock" : "Pin to Dock";

        items.push({
            text: text,
            action: function () {
                root.appLists.togglePin(entry.id);
            }
        });

        root.contextMenu.open(appItem, items);
    }

    Row {
        id: appRow

        anchors.centerIn: parent
        spacing: root.spacing

        Repeater {
            model: root.apps

            delegate: Rectangle {
                id: appItem

                required property var modelData

                property var toplevel: root.mode === "open" ? modelData : null

                property var entry: root.mode === "open" ? DesktopEntries.byId(appItem.toplevel?.appId ?? "") : DesktopEntries.applications.values.find(app => app.id === modelData)

                width: appContent.implicitWidth + root.itemHorizontalPadding * 2
                height: root.size

                radius: 10

                color: mouseArea.containsMouse ? Theme.foreground.alpha(0.10) : "transparent"

                border.width: mouseArea.containsMouse ? 1 : 0
                border.color: Theme.accent.alpha(0.25)

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Behavior on border.width {
                    NumberAnimation {
                        duration: 100
                    }
                }

                ColumnLayout {
                    id: appContent

                    anchors.centerIn: parent
                    spacing: root.itemSpacing

                    IconImage {
                        Layout.alignment: Qt.AlignHCenter

                        Layout.preferredWidth: root.icon_size
                        Layout.preferredHeight: root.icon_size

                        source: {
                            if (!appItem.entry)
                                return "";

                            return root.iconPath(appItem.entry.icon ?? "", true);
                        }

                        visible: source !== ""
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (root.mode === "open") {
                            if (!appItem.toplevel)
                                return;

                            if (mouse.button === Qt.LeftButton) {
                                appItem.toplevel.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                root.openContextMenu(appItem);
                            }
                            return;
                        }

                        if (!appItem.entry)
                            return;

                        switch (mouse.button) {
                        case Qt.LeftButton:
                            root.launchApp(appItem.entry);
                            break;
                        case Qt.RightButton:
                            root.openContextMenu(appItem);
                            break;
                        }
                    }

                    onEntered: {
                        root.tooltip.show(appItem, root.mode === "open" ? appItem.toplevel?.title ?? "" : appItem.entry?.name ?? "");
                    }

                    onExited: {
                        root.tooltip.hide();
                    }
                }
            }
        }
    }
}
