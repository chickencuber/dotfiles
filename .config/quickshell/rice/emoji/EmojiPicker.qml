import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: root

    focusable: true
    visible: false

    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    property int selectedIndex: 0

    signal closeRequested

    EmojiBackend {
        id: backend

        onOpenMenuRequested: {
            if (root.visible) {
                root.close();
                return;
            }

            backend.searchText = "";
            backend.selectionBuffer = "";
            backend.currentCategory = "Recents";
            root.selectedIndex = 0;

            root.visible = true;

            searchField.text = "";
            searchField.forceActiveFocus();

            Qt.callLater(() => {
                emojiGrid.positionViewAtBeginning();
            });
        }

        onCloseMenuRequested: {
            root.close();
        }
    }

    IpcHandler {
        target: "emoji"

        function toggle(): void {
            if (root.visible)
                root.close();
            else
                backend.openMenuRequested();
        }
    }

    function close(): void {
        backend.commitRecents();
        root.visible = false;
    }

    function currentItem() {
        if (root.selectedIndex < 0 || root.selectedIndex >= backend.filteredItems.length) {
            return null;
        }

        return backend.filteredItems[root.selectedIndex];
    }

    function selectCurrent(shiftHeld: bool): void {
        const item = root.currentItem();

        if (!item)
            return;
        backend.processSelection(item.emoji, shiftHeld);
    }

    function moveSelection(amount: int): void {
        const count = backend.filteredItems.length;

        if (count === 0) {
            root.selectedIndex = -1;
            return;
        }

        root.selectedIndex = Math.max(0, Math.min(count - 1, root.selectedIndex + amount));

        emojiGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    function moveHorizontal(amount: int): void {
        const columns = Math.max(1, Math.floor(emojiGrid.width / emojiGrid.cellWidth));

        moveSelection(amount);
    }

    function moveVertical(amount: int): void {
        const columns = Math.max(1, Math.floor(emojiGrid.width / emojiGrid.cellWidth));

        moveSelection(amount * columns);
    }

    onVisibleChanged: {
        if (!visible)
            return;
        root.selectedIndex = backend.filteredItems.length > 0 ? 0 : -1;

        Qt.callLater(() => {
            searchField.forceActiveFocus();
            emojiGrid.positionViewAtBeginning();
        });
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.close();
        }
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent

        radius: 18

        width: 500
        height: 600
        color: Theme.background

        border.width: 1
        border.color: Theme.accent

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Down) {
                root.moveVertical(1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Up) {
                root.moveVertical(-1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Right) {
                root.moveHorizontal(1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Left) {
                root.moveHorizontal(-1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_J) {
                root.moveVertical(1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_K) {
                root.moveVertical(-1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_L) {
                root.moveHorizontal(1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_H) {
                root.moveHorizontal(-1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Tab) {
                backend.cycleCategory();
                root.selectedIndex = 0;

                Qt.callLater(() => {
                    emojiGrid.positionViewAtBeginning();
                });

                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.selectCurrent((event.modifiers & Qt.ShiftModifier) !== 0);

                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Slash) {
                searchField.forceActiveFocus();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16

            spacing: 10

            // Header
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

                    color: closeMouseArea.containsMouse ? Theme.foreground.alpha(0.08) : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "×"

                        color: Theme.textMuted
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: closeMouseArea

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: root.close()
                    }
                }
            }

            // Search
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

                background: Rectangle {
                    radius: 12

                    color: searchField.activeFocus ? Theme.background.alpha(0.65) : Theme.surface

                    border.width: searchField.activeFocus ? 2 : 1

                    border.color: searchField.activeFocus ? Theme.accent : Theme.foreground.alpha(0.1)
                }

                onTextChanged: {
                    backend.searchText = text;
                    root.selectedIndex = backend.filteredItems.length > 0 ? 0 : -1;

                    Qt.callLater(() => {
                        emojiGrid.positionViewAtBeginning();
                    });
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
                        panel.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        backend.cycleCategory();
                        root.selectedIndex = 0;
                        event.accepted = true;
                    }
                }
            }

            // Categories
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: 6

                    Repeater {
                        model: backend.categories

                        delegate: Rectangle {
                            required property string modelData

                            width: categoryText.width + 24
                            height: 30

                            radius: 15

                            color: modelData === backend.currentCategory ? Theme.accent.alpha(0.15) : "transparent"

                            Text {
                                id: categoryText

                                anchors.centerIn: parent

                                text: modelData

                                color: modelData === backend.currentCategory ? Theme.accent : Theme.textMuted

                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    backend.currentCategory = modelData;
                                    root.selectedIndex = backend.filteredItems.length > 0 ? 0 : -1;

                                    searchField.text = "";

                                    Qt.callLater(() => {
                                        emojiGrid.positionViewAtBeginning();
                                    });
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    visible: backend.currentCategory === "Recents" && backend.recentItems.length > 0

                    width: 30
                    height: 30

                    radius: 15

                    color: clearMouseArea.containsMouse ? Theme.foreground.alpha(0.08) : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "⌫"

                        color: Theme.textMuted
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: clearMouseArea

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: {
                            backend.clearRecents();
                            root.selectedIndex = -1;
                        }
                    }
                }
            }

            // Emoji grid
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: emojiGrid

                    anchors.fill: parent

                    cellWidth: 58
                    cellHeight: 58

                    clip: true

                    model: backend.filteredItems

                    currentIndex: root.selectedIndex

                    highlightMoveDuration: 100

                    onCurrentIndexChanged: {
                        if (currentIndex !== root.selectedIndex)
                            root.selectedIndex = currentIndex;
                    }

                    delegate: Item {
                        id: emojiDelegate

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

                            color: emojiDelegate.selected ? Theme.accent.alpha(0.15) : emojiMouse.containsMouse ? Theme.foreground.alpha(0.06) : "transparent"

                            scale: emojiMouse.pressed ? 0.9 : emojiDelegate.selected ? 1.04 : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            text: modelData.emoji

                            font.family: "Noto Color Emoji"
                            font.pixelSize: 28
                        }

                        MouseArea {
                            id: emojiMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onEntered: {
                                root.selectedIndex = index;
                            }

                            onClicked: {
                                root.selectedIndex = index;

                                backend.processSelection(modelData.emoji, (mouse.modifiers & Qt.ShiftModifier) !== 0);
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible: backend.filteredItems.length === 0

                    text: backend.currentCategory === "Recents" && backend.recentItems.length === 0 ? "No recent emojis" : "No emojis found"

                    color: Theme.textMuted

                    font.pixelSize: 14
                }
            }

            // Footer
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
                        visible: backend.selectionBuffer !== ""

                        text: backend.selectionBuffer

                        color: Theme.text

                        font.family: "Noto Color Emoji"
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 1

                        Text {
                            Layout.fillWidth: true

                            text: {
                                const item = root.currentItem();

                                if (!item)
                                    return "Select an emoji";

                                return item.display;
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
