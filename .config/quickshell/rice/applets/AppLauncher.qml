pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../components/"
import "../services/"
import "../singletons/"

Scope {
    id: root

    property int selectedIndex: 0

    // -------------------------------------------------------------------------
    // Search
    // -------------------------------------------------------------------------

    function fuzzyScore(text: string, query: string): int {
        text = text.toLowerCase();
        query = query.toLowerCase();

        if (query === "")
            return 0;

        let score = 0;
        let textIndex = 0;
        let queryIndex = 0;
        let consecutive = 0;

        while (textIndex < text.length && queryIndex < query.length) {
            if (text[textIndex] === query[queryIndex]) {
                score += 10;
                consecutive++;
                score += consecutive * 5;

                if (textIndex === 0 || " -_.".includes(text[textIndex - 1]))
                    score += 20;

                queryIndex++;
            } else {
                consecutive = 0;
            }

            textIndex++;
        }

        if (queryIndex !== query.length)
            return -1;

        return score - text.length;
    }

    ScriptModel {
        id: filteredApps

        objectProp: "id"

        values: {
            const all = [...DesktopEntries.applications.values];
            const query = searchInput.text.trim();

            if (query === "") {
                return all.sort((a, b) => {
                    const aPinned = AppList.isPinned(a.id);
                    const bPinned = AppList.isPinned(b.id);

                    if (aPinned !== bPinned)
                        return aPinned ? -1 : 1;

                    const aRecent = AppList.recentApps.indexOf(a.id);
                    const bRecent = AppList.recentApps.indexOf(b.id);

                    if (aRecent !== -1 && bRecent !== -1)
                        return aRecent - bRecent;

                    if (aRecent !== -1)
                        return -1;

                    if (bRecent !== -1)
                        return 1;

                    return a.name.localeCompare(b.name);
                });
            }

            return all.map(app => {
                const nameScore = root.fuzzyScore(app.name ?? "", query);
                const genericScore = root.fuzzyScore(app.genericName ?? "", query);

                const keywordScore = Math.max(
                    ...(app.keywords ?? []).map(
                        keyword => root.fuzzyScore(keyword, query)
                    ),
                    -1
                );

                return {
                    app,
                    score: Math.max(nameScore, genericScore, keywordScore)
                };
            })
            .filter(item => item.score >= 0)
            .sort((a, b) => b.score - a.score)
            .map(item => item.app);
        }
    }

    // -------------------------------------------------------------------------
    // Launcher behavior
    // -------------------------------------------------------------------------

    function reset(): void {
        searchInput.text = "";
        root.selectedIndex = 0;
        results.positionViewAtBeginning();
    }

    function launchApp(entry): void {
        AppList.addRecent(entry.id);

        if (entry.runInTerminal) {
            Quickshell.execDetached([
                "xdg-terminal-exec",
                "--",
                ...entry.command
            ]);
        } else {
            entry.execute();
        }

        panel.open = false;
    }

    function launchSelected(): void {
        if (root.selectedIndex < 0 ||
            root.selectedIndex >= filteredApps.values.length)
            return;

        const entry = filteredApps.values[root.selectedIndex];

        if (entry)
            root.launchApp(entry);
    }

    function moveSelection(amount: int): void {
        const count = results.count;

        if (count <= 0) {
            root.selectedIndex = -1;
            return;
        }

        root.selectedIndex = Math.max(
            0,
            Math.min(count - 1, root.selectedIndex + amount)
        );

        results.positionViewAtIndex(
            root.selectedIndex,
            ListView.Contain
        );
    }

    // -------------------------------------------------------------------------
    // Floating panel
    // -------------------------------------------------------------------------

    FloatingPanel {
        id: panel

        ipc: "launcher"

        width: 600
        height: 500

        origin: FloatingPanel.Center
        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade
        background: "transparent"

        onAnimationFinished: {
            if (open) {
                Qt.callLater(() => searchInput.forceActiveFocus());
            } else {
                root.reset();
            }
        }

        // ---------------------------------------------------------------------
        // Launcher
        // ---------------------------------------------------------------------

        Rectangle {
            anchors.centerIn: parent

            width: 600
            height: 500

            radius: 18
            color: Theme.background

            border.width: 1
            border.color: Theme.accent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16

                spacing: 10

                // Title

                Text {
                    text: "Applications"

                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.bold: true

                    Layout.fillWidth: true
                }

                // Search

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    radius: 12

                    color: searchInput.activeFocus
                        ? Theme.background.alpha(0.65)
                        : Theme.surface

                    border.width: searchInput.activeFocus ? 2 : 1

                    border.color: searchInput.activeFocus
                        ? Theme.accent
                        : Theme.foreground.alpha(0.1)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Icon {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18

                            name: "search"
                            source: Icon.System
                            monochrome: true
                            iconColor: Theme.textMuted
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true

                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 14

                            clip: true

                            Text {
                                anchors.fill: parent

                                text: "Search applications..."
                                color: Theme.textMuted
                                font: parent.font

                                verticalAlignment: Text.AlignVCenter

                                visible: parent.text === "" &&
                                         !parent.activeFocus
                            }

                            onTextChanged: {
                                root.selectedIndex =
                                    filteredApps.values.length > 0 ? 0 : -1;

                                Qt.callLater(() => {
                                    results.positionViewAtBeginning();
                                });
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    root.moveSelection(1);
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-1);
                                } else if (
                                    event.key === Qt.Key_Return ||
                                    event.key === Qt.Key_Enter
                                ) {
                                    root.launchSelected();
                                } else if (event.key === Qt.Key_Escape) {
                                    panel.open = false;
                                } else if (event.key === Qt.Key_Tab) {
                                    root.moveSelection(1);
                                } else {
                                    return;
                                }

                                event.accepted = true;
                            }
                        }
                    }
                }

                // Result count

                Text {
                    text: results.count +
                          " application" +
                          (results.count !== 1 ? "s" : "")

                    color: Theme.textMuted
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                // Results

                ListView {
                    id: results

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: filteredApps

                    clip: true
                    spacing: 4

                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: delegateRoot

                        required property var modelData
                        required property int index

                        width: results.width
                        height: 52

                        radius: 10

                        color: index === root.selectedIndex
                            ? Theme.accent.alpha(0.15)
                            : appMouse.containsMouse
                                ? Theme.foreground.alpha(0.06)
                                : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Application entry

                            MouseArea {
                                id: appMouse

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: {
                                    root.selectedIndex = delegateRoot.index;
                                }

                                onClicked: {
                                    root.selectedIndex = delegateRoot.index;
                                    root.launchApp(delegateRoot.modelData);
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 12

                                    // Application icon

                                    Item {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: Theme.surface
                                        }

                                        Icon {
                                            anchors.fill: parent
                                            anchors.margins: 4

                                            name: delegateRoot.modelData.icon ?? ""
                                            source: Icon.System
                                        }
                                    }

                                    // Application information

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true

                                            text: delegateRoot.modelData.name ?? ""

                                            color: index === root.selectedIndex
                                                ? Theme.accent
                                                : Theme.text

                                            font.family: Theme.font
                                            font.pixelSize: 13
                                            font.bold: index === root.selectedIndex

                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Text {
                                            Layout.fillWidth: true

                                            text: delegateRoot.modelData.genericName ??
                                                  delegateRoot.modelData.comment ?? ""

                                            color: Theme.textMuted

                                            font.family: Theme.font
                                            font.pixelSize: 11

                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }
                                    }

                                    // Recent badge

                                    Rectangle {
                                        visible: AppList.recentApps.includes(
                                            delegateRoot.modelData.id
                                        )

                                        Layout.alignment: Qt.AlignVCenter

                                        width: recentText.implicitWidth + 14
                                        height: 22

                                        radius: 11
                                        color: Theme.surface

                                        border.width: 1
                                        border.color: Theme.accent

                                        Text {
                                            id: recentText

                                            anchors.centerIn: parent

                                            text: "Recent"

                                            color: Theme.text
                                            font.family: Theme.font
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }

                            // Pin button

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30

                                radius: 8

                                color: pinMouse.containsMouse
                                    ? Theme.accent.alpha(0.15)
                                    : "transparent"

                                Icon {
                                    anchors.centerIn: parent

                                    width: 18
                                    height: 18

                                    filled: true
                                    name: AppList.isPinned(
                                        delegateRoot.modelData.id
                                    ) ? "keep" : "add"

                                    iconColor: AppList.isPinned(
                                        delegateRoot.modelData.id
                                    ) ? Theme.accent : Theme.textMuted
                                }

                                MouseArea {
                                    id: pinMouse

                                    anchors.fill: parent

                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onEntered: {
                                        root.selectedIndex = delegateRoot.index;
                                    }

                                    onClicked: {
                                        AppList.togglePin(
                                            delegateRoot.modelData.id
                                        );
                                    }
                                }
                            }
                        }
                    }

                    // Empty state

                    Text {
                        anchors.centerIn: parent

                        text: searchInput.text === ""
                            ? "No applications"
                            : "No applications found"

                        color: Theme.textMuted
                        font.family: Theme.font
                        font.pixelSize: 14

                        visible: results.count === 0
                    }
                }
            }
        }
    }
}
