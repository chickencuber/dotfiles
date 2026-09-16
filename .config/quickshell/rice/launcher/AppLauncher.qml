import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import ".."
import QtQuick.Layouts

Scope {
    id: root
    property string font: "Hack Nerd Font"
    property list<string> recentApps: []
    FileView {
        id: recentFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/rice/recent-apps.json"

        function save() {
            setText(JSON.stringify(root.recentApps));
        }
        onLoadedChanged: {
            if (loaded) {
                root.recentApps = JSON.parse(text());
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcherPanel.visible = !launcherPanel.visible;
            if (launcherPanel.visible) {
                searchInput.text = "";
                root.selectedIndex = -1;
                searchInput.forceActiveFocus();
            }
        }
    }
    function iconPath(name: string, check: bool): string {
        const themed = Quickshell.iconPath(name, true);
        if (themed !== "")
            return themed;
        return Quickshell.iconPath(Quickshell.env("HOME") + "/.local/share/icons/" + name + ".png", check);
    }
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

                if (textIndex === 0 || text[textIndex - 1] === " " || text[textIndex - 1] === "-" || text[textIndex - 1] === "_" || text[textIndex - 1] === ".") {
                    score += 20;
                }

                queryIndex++;
            } else {
                consecutive = 0;
            }

            textIndex++;
        }

        if (queryIndex !== query.length)
            return -1;

        score -= text.length;

        return score;
    }

    property int selectedIndex: 0

    ScriptModel {
        id: filteredApps
        objectProp: "id"
        values: {
            const all = [...DesktopEntries.applications.values];
            const q = searchInput.text.trim();

            if (q === "")
                return all.sort((a, b) => {
                    const ai = recentApps.indexOf(a.id);
                    const bi = recentApps.indexOf(b.id);

                    if (ai !== -1 && bi !== -1)
                        return ai - bi;

                    if (ai !== -1)
                        return -1;

                    if (bi !== -1)
                        return 1;

                    return a.name.localeCompare(b.name);
                });

            return all.map(app => {
                const nameScore = fuzzyScore(app.name ?? "", q);
                const genericScore = fuzzyScore(app.genericName ?? "", q);
                const keywordScore = Math.max(...(app.keywords ?? []).map(k => fuzzyScore(k, q)), -1);

                return {
                    app: app,
                    score: Math.max(nameScore, genericScore, keywordScore)
                };
            }).filter(x => x.score >= 0).sort((a, b) => b.score - a.score).map(x => x.app);
        }
    }

    function launchApp(entry) {
        recentApps = [entry.id, ...recentApps.filter(id => id !== entry.id)].slice(0, 5);
        recentFile.save();
        if (entry.runInTerminal) {
            Quickshell.execDetached(["xdg-terminal-exec", "--", ...entry.command]);
        } else {
            entry.execute();
        }

        launcherPanel.visible = false;
    }

    PanelWindow {
        id: launcherPanel
        visible: false
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: launcherPanel.visible = false
        }

        Rectangle {
            id: launcherBox
            anchors.centerIn: parent
            width: 580
            height: 480
            radius: 16
            color: Theme.background
            border.color: Theme.accent
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "  Applications"
                    color: Theme.text
                    font.pixelSize: 14
                    font.family: root.font
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 10
                    color: Theme.surface
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.foreground
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: ""
                            color: Theme.textMuted
                            font.pixelSize: 16
                            font.family: root.font
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 15
                            font.family: root.font
                            clip: true
                            focus: true
                            Accessible.role: Accessible.EditableText
                            Accessible.name: "Search applications"

                            Text {
                                anchors.fill: parent
                                text: "Type to search..."
                                color: Theme.textMuted
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: {
                                root.selectedIndex = text === "" ? -1 : 0;
                                resultsList.positionViewAtBeginning();
                            }

                            Keys.onEscapePressed: launcherPanel.visible = false

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    event.accepted = true;
                                    root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                } else if (event.key === Qt.Key_Up) {
                                    event.accepted = true;
                                    root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true;
                                    if (root.selectedIndex >= 0) {
                                        const entry = filteredApps.values[root.selectedIndex];
                                        if (entry)
                                            root.launchApp(entry);
                                    }
                                } else if (event.key === Qt.Key_Tab) {
                                    event.accepted = true;
                                    root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                                }
                            }
                        }
                    }
                }

                Text {
                    text: resultsList.count + " application" + (resultsList.count !== 1 ? "s" : "")
                    color: Theme.textMuted
                    font.pixelSize: 11
                    font.family: root.font
                }

                ListView {
                    id: resultsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: filteredApps
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 150
                    highlightMoveVelocity: -1

                    delegate: Rectangle {
                        id: delegateRoot
                        required property var modelData
                        required property int index

                        Accessible.role: Accessible.Button
                        Accessible.name: (modelData.name ?? "Application") + (modelData.genericName ? " - " + modelData.genericName : "")

                        width: resultsList.width
                        height: 44
                        radius: 8
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            color: root.selectedIndex === delegateRoot.index ? Theme.accent : Theme.background
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Item {
                                width: 28
                                height: 28
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.surface
                                }
                                IconImage {
                                    anchors.fill: parent
                                    source: root.iconPath(delegateRoot.modelData.icon ?? "", true)
                                    visible: (delegateRoot.modelData.icon ?? "") !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    color: Theme.accent
                                    font.pixelSize: 20
                                    font.family: root.font
                                    visible: (delegateRoot.modelData.icon ?? "") === ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    text: delegateRoot.modelData.name ?? ""
                                    color: root.selectedIndex === delegateRoot.index ? Theme.accentText : Theme.text
                                    font.pixelSize: 13
                                    font.family: root.font
                                    font.bold: root.selectedIndex === delegateRoot.index
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""
                                    color: root.selectedIndex === delegateRoot.index ? Theme.accentTextMuted : Theme.textMuted
                                    font.pixelSize: 11
                                    font.family: root.font
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                }
                            }
                            Rectangle {
                                visible: recentApps.includes(delegateRoot.modelData.id)
                                width: recentText.width + 10
                                height: 20
                                radius: 10
                                color: Theme.surface
                                border.width: 1
                                border.color: Theme.accent

                                Text {
                                    id: recentText
                                    padding: 5
                                    anchors.centerIn: parent
                                    text: "Recent"
                                    color: Theme.text
                                    font.pixelSize: 13
                                    font.family: root.font
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchApp(delegateRoot.modelData)
                            onPositionChanged: root.selectedIndex = delegateRoot.index
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "  No applications found"
                        color: Theme.textMuted
                        font.pixelSize: 14
                        font.family: root.font
                        visible: resultsList.count === 0 && searchInput.text !== ""
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintUp.width + 8
                            height: 18
                            radius: 4
                            color: Theme.surface
                            Text {
                                id: hintUp
                                anchors.centerIn: parent
                                text: "↑↓"
                                color: Theme.textMuted
                                font.pixelSize: 10
                                font.family: root.font
                            }
                        }
                        Text {
                            text: "navigate"
                            color: Theme.textMuted
                            font.pixelSize: 10
                            font.family: root.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEnter.width + 8
                            height: 18
                            radius: 4
                            color: Theme.surface
                            Text {
                                id: hintEnter
                                anchors.centerIn: parent
                                text: "⏎"
                                color: Theme.textMuted
                                font.pixelSize: 10
                                font.family: root.font
                            }
                        }
                        Text {
                            text: "launch"
                            color: Theme.textMuted
                            font.pixelSize: 10
                            font.family: root.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEsc.width + 8
                            height: 18
                            radius: 4
                            color: Theme.surface
                            Text {
                                id: hintEsc
                                anchors.centerIn: parent
                                text: "esc"
                                color: Theme.textMuted
                                font.pixelSize: 10
                                font.family: root.font
                            }
                        }
                        Text {
                            text: "close"
                            color: Theme.textMuted
                            font.pixelSize: 10
                            font.family: root.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
