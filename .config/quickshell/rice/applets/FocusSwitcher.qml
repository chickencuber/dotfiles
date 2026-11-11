pragma Singleton

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import "../components/"
import "../singletons/"

Scope {
    id: root

    property var windows: []
    property var filteredWindows: []
    property int selectedIndex: -1
    property var pendingWindow: null

    // -------------------------------------------------------------------------
    // Window filtering
    // -------------------------------------------------------------------------

    function refreshWindows(): void {
        root.windows = ToplevelManager.toplevels.values;
        root.filterWindows();
    }

    function filterWindows(): void {
        const query = searchField.text.toLowerCase().trim();

        if (query === "") {
            root.filteredWindows = root.windows;
        } else {
            root.filteredWindows = root.windows.filter(window => {
                const title = window.title ?? "";
                const appId = window.appId ?? "";

                return title.toLowerCase().includes(query) || appId.toLowerCase().includes(query);
            });
        }

        root.selectedIndex = root.filteredWindows.length > 0 ? 0 : -1;

        Qt.callLater(() => {
            windowList.positionViewAtBeginning();
        });
    }

    // -------------------------------------------------------------------------
    // Selection
    // -------------------------------------------------------------------------

    function moveSelection(amount: int): void {
        const count = root.filteredWindows.length;

        if (count === 0) {
            root.selectedIndex = -1;
            return;
        }

        if (root.selectedIndex < 0)
            root.selectedIndex = 0;

        root.selectedIndex = Math.max(0, Math.min(count - 1, root.selectedIndex + amount));

        windowList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function focusCurrent(): void {
        if (root.selectedIndex < 0)
            return;
        const selected = root.filteredWindows[root.selectedIndex];

        if (!selected)
            return;

        panel.open = false;

        activationTimer.targetWindow = selected;
    }
    Timer {
        id: activationTimer
        interval: 1
        repeat: false

        property var targetWindow: null

        onTriggered: {
            if (targetWindow) {
                targetWindow.activate();
                targetWindow = null;
            }
        }
    }

    function reset(): void {
        activationTimer.running = true;
        searchField.text = "";

        root.selectedIndex = -1;
        root.windows = [];
        root.filteredWindows = [];
    }

    // -------------------------------------------------------------------------
    // Floating panel
    // -------------------------------------------------------------------------

    FloatingPanel {
        id: panel

        ipc: "windows"

        width: 600
        height: 500

        origin: FloatingPanel.Center
        background: "transparent"

        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade

        onAnimationFinished: opening => {
            if (opening) {
                root.refreshWindows();

                Qt.callLater(() => {
                    searchField.forceActiveFocus();
                });
            } else {
                root.reset();
            }
        }

        // ---------------------------------------------------------------------
        // Panel content
        // ---------------------------------------------------------------------

        Rectangle {
            anchors.fill: parent

            radius: 18

            color: Theme.background

            border.width: 1
            border.color: Theme.accent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16

                spacing: 10

                // Search
                TextField {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    placeholderText: "Search windows..."

                    color: Theme.text
                    placeholderTextColor: Theme.textMuted

                    font.family: Theme.font
                    font.pixelSize: 14

                    background: Rectangle {
                        radius: 12

                        color: searchField.activeFocus ? Theme.background.alpha(0.65) : Theme.surface

                        border.width: searchField.activeFocus ? 2 : 1

                        border.color: searchField.activeFocus ? Theme.accent : Theme.foreground.alpha(0.1)
                    }

                    onTextChanged: root.filterWindows()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.focusCurrent();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            panel.open = false;
                            event.accepted = true;
                        }
                    }
                }

                // Window list
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: windowList

                        anchors.fill: parent

                        clip: true
                        spacing: 4

                        model: root.filteredWindows

                        delegate: Rectangle {
                            id: delegateRoot

                            required property int index
                            required property var modelData

                            width: windowList.width
                            height: 52

                            radius: 10

                            color: index === root.selectedIndex ? Theme.accent.alpha(0.15) : windowMouse.containsMouse ? Theme.foreground.alpha(0.06) : "transparent"

                            RowLayout {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                spacing: 10

                                Item {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    Layout.alignment: Qt.AlignVCenter

                                    property var desktopEntry: DesktopEntries.byId(modelData.appId)

                                    property string iconName: desktopEntry?.icon ?? ""

                                    Rectangle {
                                        anchors.fill: parent

                                        radius: 8

                                        color: index === root.selectedIndex ? Theme.accent.alpha(0.15) : Theme.surface
                                    }

                                    IconImage {
                                        anchors.fill: parent

                                        source: parent.iconName !== "" ? Quickshell.iconPath(parent.iconName) : ""

                                        smooth: true
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    text: modelData.title

                                    color: index === root.selectedIndex ? Theme.accent : Theme.text

                                    font.family: Theme.font
                                    font.pixelSize: 13

                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: windowMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onEntered: {
                                    root.selectedIndex = index;
                                }

                                onClicked: {
                                    root.selectedIndex = index;
                                    root.focusCurrent();
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        visible: root.filteredWindows.length === 0

                        text: root.windows.length === 0 ? "No windows" : "No matches"

                        color: Theme.textMuted
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
