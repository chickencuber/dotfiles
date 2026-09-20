import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property string font: "Hack Nerd Font"
    property list<string> recentApps: []
    property int selectedIndex: 0

    FileView {
        id: recentFile

        path: Quickshell.env("HOME") + "/.local/state/quickshell/rice/recent-apps.json"

        function save() {
            setText(JSON.stringify(root.recentApps));
        }

        onLoadedChanged: {
            if (loaded) {
                try {
                    root.recentApps = JSON.parse(text());
                } catch (e) {
                    root.recentApps = [];
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcherPanel.visible = !launcherPanel.visible;

            if (launcherPanel.visible) {
                searchInput.text = "";
                root.selectedIndex = 0;

                Qt.callLater(() => {
                    searchInput.forceActiveFocus();
                });
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

    ScriptModel {
        id: filteredApps

        objectProp: "id"

        values: {
            const all = [...DesktopEntries.applications.values];
            const query = searchInput.text.trim();

            if (query === "") {
                return all.sort((a, b) => {
                    const ai = root.recentApps.indexOf(a.id);
                    const bi = root.recentApps.indexOf(b.id);

                    if (ai !== -1 && bi !== -1)
                        return ai - bi;

                    if (ai !== -1)
                        return -1;

                    if (bi !== -1)
                        return 1;

                    return a.name.localeCompare(b.name);
                });
            }

            return all.map(app => {
                const nameScore = root.fuzzyScore(app.name ?? "", query);

                const genericScore = root.fuzzyScore(app.genericName ?? "", query);

                const keywordScore = Math.max(...(app.keywords ?? []).map(k => root.fuzzyScore(k, query)), -1);

                return {
                    app: app,
                    score: Math.max(nameScore, genericScore, keywordScore)
                };
            }).filter(x => x.score >= 0).sort((a, b) => b.score - a.score).map(x => x.app);
        }
    }

    function launchApp(entry): void {
        root.recentApps = [entry.id, ...root.recentApps.filter(id => id !== entry.id)].slice(0, 5);

        recentFile.save();

        if (entry.runInTerminal) {
            Quickshell.execDetached(["xdg-terminal-exec", "--", ...entry.command]);
        } else {
            entry.execute();
        }

        launcherPanel.visible = false;
    }

    function moveSelection(amount: int): void {
        const count = resultsList.count;

        if (count <= 0) {
            root.selectedIndex = -1;
            return;
        }

        root.selectedIndex = Math.max(0, Math.min(count - 1, root.selectedIndex + amount));

        resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function launchSelected(): void {
        if (root.selectedIndex < 0 || root.selectedIndex >= filteredApps.values.length)
            return;
        const entry = filteredApps.values[root.selectedIndex];

        if (entry)
            root.launchApp(entry);
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

            onClicked: {
                launcherPanel.visible = false;
            }
        }

        Rectangle {
            id: launcherBox

            anchors.centerIn: parent

            width: 600
            height: 500

            radius: 18

            color: Theme.background

            border.width: 1
            border.color: Theme.accent

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16

                spacing: 10

                Text {
                    text: "Applications"

                    color: Theme.text

                    font.family: root.font
                    font.pixelSize: 14
                    font.bold: true

                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    radius: 12

                    color: searchInput.activeFocus ? Theme.background.alpha(0.65) : Theme.surface

                    border.width: searchInput.activeFocus ? 2 : 1

                    border.color: searchInput.activeFocus ? Theme.accent : Theme.foreground.alpha(0.1)

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
                            text: "󰍉"

                            color: Theme.textMuted

                            font.family: root.font
                            font.pixelSize: 15

                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            color: Theme.text

                            font.family: root.font
                            font.pixelSize: 14

                            clip: true

                            focus: true

                            Text {
                                anchors.fill: parent

                                text: "Search applications..."

                                color: Theme.textMuted

                                font: parent.font

                                verticalAlignment: Text.AlignVCenter

                                visible: parent.text === "" && !parent.activeFocus
                            }

                            onTextChanged: {
                                root.selectedIndex = filteredApps.values.length > 0 ? 0 : -1;

                                Qt.callLater(() => {
                                    resultsList.positionViewAtBeginning();
                                });
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.launchSelected();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    launcherPanel.visible = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Tab) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                Text {
                    text: resultsList.count + " application" + (resultsList.count !== 1 ? "s" : "")

                    color: Theme.textMuted

                    font.family: root.font
                    font.pixelSize: 11
                }

                ListView {
                    id: resultsList

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

                        width: resultsList.width
                        height: 52

                        radius: 10

                        color: index === root.selectedIndex ? Theme.accent.alpha(0.15) : appMouse.containsMouse ? Theme.foreground.alpha(0.06) : "transparent"

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            spacing: 12

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent

                                    radius: 8

                                    color: index === root.selectedIndex ? Theme.accent.alpha(0.15) : Theme.surface
                                }

                                IconImage {
                                    anchors.fill: parent

                                    anchors.margins: 4

                                    source: root.iconPath(delegateRoot.modelData.icon ?? "", true)

                                    visible: (delegateRoot.modelData.icon ?? "") !== ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                spacing: 1

                                Text {
                                    Layout.fillWidth: true

                                    text: delegateRoot.modelData.name ?? ""

                                    color: index === root.selectedIndex ? Theme.accent : Theme.text

                                    font.family: root.font
                                    font.pixelSize: 13

                                    font.bold: index === root.selectedIndex

                                    elide: Text.ElideRight

                                    maximumLineCount: 1
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""

                                    color: Theme.textMuted

                                    font.family: root.font
                                    font.pixelSize: 11

                                    elide: Text.ElideRight

                                    visible: text !== ""
                                }
                            }

                            Rectangle {
                                visible: root.recentApps.includes(delegateRoot.modelData.id)

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

                                    font.family: root.font
                                    font.pixelSize: 10
                                }
                            }
                        }

                        MouseArea {
                            id: appMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                root.selectedIndex = delegateRoot.index;
                            }

                            onClicked: {
                                root.selectedIndex = delegateRoot.index;

                                root.launchApp(delegateRoot.modelData);
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: searchInput.text === "" ? "No applications" : "No applications found"

                        color: Theme.textMuted

                        font.family: root.font
                        font.pixelSize: 14

                        visible: resultsList.count === 0
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    radius: 10

                    color: Theme.surface

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        spacing: 16

                        Row {
                            spacing: 5

                            Rectangle {
                                width: hintNav.implicitWidth + 10
                                height: 20

                                radius: 5

                                color: Theme.background

                                Text {
                                    id: hintNav

                                    anchors.centerIn: parent

                                    text: "↑↓"

                                    color: Theme.textMuted

                                    font.family: root.font
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                text: "navigate"

                                color: Theme.textMuted

                                font.family: root.font
                                font.pixelSize: 10

                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 5

                            Rectangle {
                                width: hintEnter.implicitWidth + 10
                                height: 20

                                radius: 5

                                color: Theme.background

                                Text {
                                    id: hintEnter

                                    anchors.centerIn: parent

                                    text: "⏎"

                                    color: Theme.textMuted

                                    font.family: root.font
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                text: "launch"

                                color: Theme.textMuted

                                font.family: root.font
                                font.pixelSize: 10

                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 5

                            Rectangle {
                                width: hintEsc.implicitWidth + 10
                                height: 20

                                radius: 5

                                color: Theme.background

                                Text {
                                    id: hintEsc

                                    anchors.centerIn: parent

                                    text: "esc"

                                    color: Theme.textMuted

                                    font.family: root.font
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                text: "close"

                                color: Theme.textMuted

                                font.family: root.font
                                font.pixelSize: 10

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
}
