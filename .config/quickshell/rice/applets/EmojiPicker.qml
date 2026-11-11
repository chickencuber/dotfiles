pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../components/"
import "../singletons/"

Scope {
    id: root

    property alias open: panel.open

    property string emojiListPath: Quickshell.env("HOME") + "/.cache/quickshell/emojis.json"

    property string recentsCachePath: Quickshell.env("HOME") + "/.local/state/quickshell/rice/recent_emojis.json"

    property var allItems: []
    property var filteredItems: []
    property var recentItems: []
    property var pendingRecents: []

    property string selectionBuffer: ""
    property string searchText: ""
    property string currentCategory: "Recents"

    property int selectedIndex: 0

    readonly property var categories: ["Recents", "All"]

    function filterEmojis(items, query) {
        query = query.toLowerCase().trim();

        if (query === "")
            return items;

        return items.filter(item => item.searchString.includes(query)).slice(0, 50);
    }

    function parseEmojiJson(text) {
        const data = JSON.parse(text);
        const result = [];

        for (const emoji in data) {
            const tags = data[emoji] || [];
            const display = tags.length > 0 ? tags[0].replace(/_/g, " ") : "emoji";

            result.push({
                emoji: emoji,
                display: display,
                searchString: (display + " " + tags.join(" ")).toLowerCase()
            });
        }

        return result;
    }

    function updateRecents(emoji, items, recents) {
        const item = items.find(x => x.emoji === emoji);

        if (!item)
            return recents;

        return [item, ...recents.filter(x => x.emoji !== emoji)].slice(0, 100);
    }

    function triggerSearch() {
        const query = searchText.trim();

        let items;

        if (query !== "" || currentCategory === "All")
            items = allItems;
        else
            items = recentItems;

        filteredItems = filterEmojis(items, query);
        selectedIndex = filteredItems.length > 0 ? 0 : -1;
    }

    function processSelection(emoji, isShift) {
        pendingRecents.push(emoji);

        if (isShift) {
            selectionBuffer += emoji;
            return;
        }

        const result = selectionBuffer + emoji;

        selectionBuffer = "";

        copyProcess.selectedEmoji = result;
        panel.open = false;
    }

    function commitRecents() {
        if (pendingRecents.length === 0)
            return;
        let updated = recentItems;

        for (const emoji of pendingRecents)
            updated = updateRecents(emoji, allItems, updated);

        recentItems = updated;
        pendingRecents = [];

        saveRecentsProcess.running = true;
    }

    function resetPicker() {
        searchText = "";
        selectionBuffer = "";
        currentCategory = "Recents";
        selectedIndex = 0;

        searchField.text = "";
        triggerSearch();
    }

    function clearRecents() {
        recentItems = [];
        filteredItems = [];
        pendingRecents = [];

        saveRecentsProcess.running = true;
        triggerSearch();
    }

    function cycleCategory() {
        const index = categories.indexOf(currentCategory);
        currentCategory = categories[(index + 1) % categories.length];
    }

    function currentItem() {
        if (selectedIndex < 0 || selectedIndex >= filteredItems.length)
            return null;

        return filteredItems[selectedIndex];
    }

    function selectCurrent(shiftHeld) {
        const item = currentItem();

        if (item)
            processSelection(item.emoji, shiftHeld);
    }

    function moveSelection(amount) {
        const count = filteredItems.length;

        if (count === 0) {
            selectedIndex = -1;
            return;
        }

        selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + amount));

        emojiGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
    }

    function moveHorizontal(amount) {
        moveSelection(amount);
    }

    function moveVertical(amount) {
        const columns = Math.max(1, Math.floor(emojiGrid.width / emojiGrid.cellWidth));

        moveSelection(amount * columns);
    }

    Process {
        id: updateEmojisProcess

        command: ["bash", Quickshell.shellPath("scripts/download_emojis.sh")]

        Component.onCompleted: running = true

        onRunningChanged: {
            if (!running)
                loadEmojisProcess.running = true;
        }
    }

    Process {
        id: loadEmojisProcess

        command: ["cat", root.emojiListPath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allItems = root.parseEmojiJson(text);
                    loadRecentsProcess.running = true;
                } catch (error) {
                    console.error("Failed to parse emojis:", error);
                }
            }
        }
    }

    Process {
        id: loadRecentsProcess

        command: ["cat", root.recentsCachePath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved = JSON.parse(text);

                    if (!Array.isArray(saved)) {
                        root.triggerSearch();
                        return;
                    }

                    root.recentItems = saved.map(emoji => root.allItems.find(item => item.emoji === emoji)).filter(Boolean);
                } catch (error) {
                    root.recentItems = [];
                }

                root.triggerSearch();
            }
        }

        onExited: root.triggerSearch()
    }

    Process {
        id: saveRecentsProcess

        property string jsonString: JSON.stringify(root.recentItems.map(item => item.emoji))

        command: ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && " + "printf '%s' \"$2\" > \"$1\"", "_", root.recentsCachePath, jsonString]
    }

    Process {
        id: copyProcess

        property string selectedEmoji: ""

        command: ["bash", "-c", "printf '%s' \"$1\" | wl-copy && wtype \"$1\"", "_", selectedEmoji]

        onExited: selectedEmoji = ""
    }

    Timer {
        id: copyTimer
        interval: 1
        repeat: false

        onTriggered: {
            copyProcess.running = true;
        }
    }
    FloatingPanel {
        id: panel

        ipc: "emoji"

        width: 500
        height: 600

        background: "transparent"
        origin: FloatingPanel.Center

        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade

        onAnimationFinished: {
            if (open) {
                Qt.callLater(() => {
                    searchField.forceActiveFocus();
                    emojiGrid.positionViewAtBeginning();
                });
            } else {
                root.commitRecents();
                root.resetPicker();

                if (copyProcess.selectedEmoji !== "")
                    copyTimer.running = true;
            }
        }

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

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Emoji"
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        width: 32
                        height: 32
                        radius: 16

                        color: closeMouse.containsMouse ? Theme.foreground.alpha(0.08) : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            name: "close"
                            width: 16
                            height: 16
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: panel.open = false
                        }
                    }
                }

                TextField {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    leftPadding: 16
                    rightPadding: 16

                    placeholderText: "Search emojis..."
                    color: Theme.text
                    placeholderTextColor: Theme.textMuted
                    font.pixelSize: 14

                    onTextChanged: {
                        root.searchText = text;
                        Qt.callLater(() => emojiGrid.positionViewAtBeginning());
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            root.moveVertical(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveVertical(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            root.moveHorizontal(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            root.moveHorizontal(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.selectCurrent((event.modifiers & Qt.ShiftModifier) !== 0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            panel.open = false;
                        } else if (event.key === Qt.Key_Tab) {
                            root.cycleCategory();
                            event.accepted = true;
                        }
                    }

                    background: Rectangle {
                        radius: 12
                        color: searchField.activeFocus ? Theme.background.alpha(0.65) : Theme.surface

                        border.width: searchField.activeFocus ? 2 : 1
                        border.color: searchField.activeFocus ? Theme.accent : Theme.foreground.alpha(0.1)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: root.categories

                            delegate: Rectangle {
                                required property string modelData

                                width: categoryText.width + 24
                                height: 30
                                radius: 15

                                color: modelData === root.currentCategory ? Theme.accent.alpha(0.15) : "transparent"

                                Text {
                                    id: categoryText
                                    anchors.centerIn: parent

                                    text: modelData
                                    color: modelData === root.currentCategory ? Theme.accent : Theme.textMuted
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {
                                        root.currentCategory = modelData;
                                        searchField.text = "";
                                        root.selectedIndex = root.filteredItems.length > 0 ? 0 : -1;
                                        emojiGrid.positionViewAtBeginning();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        visible: root.currentCategory === "Recents" && root.recentItems.length > 0

                        width: 30
                        height: 30
                        radius: 15

                        color: clearMouse.containsMouse ? Theme.foreground.alpha(0.08) : "transparent"

                        Icon {
                            anchors.centerIn: parent
                            name: "delete"
                            width: 16
                            height: 16
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.clearRecents();
                                root.selectedIndex = -1;
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: emojiGrid

                        anchors.fill: parent

                        cellWidth: 58
                        cellHeight: 58
                        clip: true

                        model: root.filteredItems
                        currentIndex: root.selectedIndex

                        highlightMoveDuration: 100

                        onCurrentIndexChanged: {
                            if (currentIndex !== root.selectedIndex)
                                root.selectedIndex = currentIndex;
                        }

                        delegate: Item {
                            required property int index
                            required property var modelData

                            width: emojiGrid.cellWidth
                            height: emojiGrid.cellHeight

                            property bool selected: index === root.selectedIndex

                            Rectangle {
                                anchors.centerIn: parent

                                width: 48
                                height: 48
                                radius: 12

                                color: parent.selected ? Theme.accent.alpha(0.15) : emojiMouse.containsMouse ? Theme.foreground.alpha(0.06) : "transparent"

                                scale: emojiMouse.pressed ? 0.9 : parent.selected ? 1.04 : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 100
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                text: modelData.emoji
                                font.family: Theme.emojiFont
                                font.pixelSize: 28
                            }

                            MouseArea {
                                id: emojiMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                onEntered: root.selectedIndex = index

                                onClicked: {
                                    root.selectedIndex = index;
                                    root.processSelection(modelData.emoji, (mouse.modifiers & Qt.ShiftModifier) !== 0);
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        visible: root.filteredItems.length === 0

                        text: root.currentCategory === "Recents" && root.recentItems.length === 0 ? "No recent emojis" : "No emojis found"

                        color: Theme.textMuted
                        font.pixelSize: 14
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52

                    radius: 12
                    color: Theme.surface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            visible: root.selectionBuffer !== ""

                            text: root.selectionBuffer
                            color: Theme.text
                            font.family: Theme.emojiFont
                            font.pixelSize: 22
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true

                                text: {
                                    const item = root.currentItem();
                                    return item ? item.display : "Select an emoji";
                                }

                                color: Theme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Enter to select • Shift+Enter for multiple"
                                color: Theme.textMuted
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
