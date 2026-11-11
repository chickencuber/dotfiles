pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Wayland

import "../singletons/"
import "../services/"
import "../components/"

Module {
    id: root

    enum Mode {
        Pinned,
        Open,
        Recent
    }

    property int mode: BarAppList.Pinned
    property int spacing: 6
    property int size: bar_thickness
    property int icon_size: 22
    property int horizontalPadding: 12
    property Component background: Component {
        Rectangle {
            color: Theme.background
            radius: 10
            border.color: Theme.accent
            border.width: 1
        }
    }

    readonly property var apps: {
        if (mode === BarAppList.Open)
            return ToplevelManager.toplevels;
        if (mode === BarAppList.Recent)
            return AppList.recentApps;
        return AppList.pinnedApps;
    }

    implicitWidth: content.implicitWidth
    implicitHeight: size

    function launchApp(entry): void {
        if (!entry)
            return;

        AppList.addRecent(entry.id);

        if (entry.runInTerminal)
            Quickshell.execDetached(["xdg-terminal-exec", "--", ...entry.command]);
        else
            entry.execute();
    }

    function openContextMenu(item): void {
        const window = item.toplevel;
        const entry = item.entry;
        const isOpen = mode === BarAppList.Open;

        if (isOpen && !window || !isOpen && !entry)
            return;

        const items = [];

        items.push({
            text: isOpen ? "Focus" : "Open",
            action: function () {
                if (isOpen) {
                    ShellContextMenu.close();
                    Qt.callLater(() => window.activate());
                } else {
                    launchApp(entry);
                }
            }
        });

        if (entry?.actions?.length) {
            items.push({
                separator: true
            });

            for (const action of entry.actions) {
                items.push({
                    text: action.name,
                    action: function () {
                        action.execute();
                    }
                });
            }
        }

        if (isOpen) {
            items.push({
                separator: true
            });
            items.push({
                text: "Close",
                action: function () {
                    window.close();
                }
            });
        }

        if (entry) {
            items.push({
                separator: true
            });
            items.push({
                text: AppList.isPinned(entry.id) ? "Unpin from Dock" : "Pin to Dock",
                action: function () {
                    AppList.togglePin(entry.id);
                }
            });
        }

        ShellContextMenu.open(item, items);
    }

    Item {
        id: content
        implicitWidth: appRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: root.bar_thickness

        Loader {
            anchors.fill: parent
            sourceComponent: root.background
        }

        Row {
            id: appRow

            anchors.centerIn: parent
            spacing: root.spacing

            Repeater {
                model: root.apps

                delegate: Item {
                    id: appItem

                    required property var modelData

                    readonly property var toplevel: root.mode === BarAppList.Open ? modelData : null

                    readonly property var entry: root.mode === BarAppList.Open ? DesktopEntries.byId(toplevel?.appId ?? "") : DesktopEntries.applications.values.find(app => app.id === modelData)

                    readonly property string icon: ShellContext.iconPath(entry?.icon ?? "")

                    visible: icon !== ""
                    width: root.size
                    height: root.size

                    IconImage {
                        anchors.fill: parent
                        source: appItem.icon
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.foreground.alpha(0.10)
                        opacity: mouseArea.containsMouse ? 1 : 0
                        radius: 10
                        border.width: mouseArea.containsMouse ? 1 : 0
                        border.color: Theme.accent.alpha(0.25)
                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        z: 100
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (root.mode === BarAppList.Open) {
                                if (mouse.button === Qt.LeftButton)
                                    appItem.toplevel?.activate();
                                else
                                    root.openContextMenu(appItem);
                            } else if (appItem.entry) {
                                if (mouse.button === Qt.LeftButton)
                                    root.launchApp(appItem.entry);
                                else
                                    root.openContextMenu(appItem);
                            }
                        }
                    }

                    ToolTip {
                        target: appItem
                        text: root.mode === BarAppList.Open ? appItem.toplevel?.title ?? "" : appItem.entry?.name ?? ""
                    }
                }
            }
        }
    }
}
