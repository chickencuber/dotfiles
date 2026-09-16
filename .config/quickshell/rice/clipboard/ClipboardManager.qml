import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: root

    visible: false

    color: "transparent"
    anchors {
        top:true
        left: true
        right: true
        bottom: true
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    property var entries: []
    property var filteredEntries: []
    property int selectedIndex: -1

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            if (root.visible) {
                root.close();
                return;
            }

            root.open();
        }
    }

    Process {
        id: clearProcess

        command: ["cliphist", "wipe"]

        onExited: {
            listProcess.running = true;
        }
    }

    Process {
        id: listProcess

        command: ["bash", Quickshell.shellPath("scripts/cliphist-visual.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseEntries(this.text);
            }
        }
    }

    Process {
        id: decodeProcess

        property string selectedEntry: ""

        command: ["bash", "-c", "printf \"$1\" | cliphist decode | wl-copy", "_", selectedEntry]

        onExited: {
            selectedEntry = "";
            root.close();
        }
    }

    Process {
        id: deleteProcess

        property string selectedEntry: ""
        property string selectedId: ""

        command: ["bash", "-c", "printf '%s\\n' \"$1\" | cliphist delete && " + "rm -f /tmp/cliphist/\"$2\".*", "_", selectedEntry, selectedId]

        onExited: {
            selectedEntry = "";
            selectedId = "";
            listProcess.running = true;
        }
    }

    function open(): void {
        root.visible = true;

        searchField.text = "";

        listProcess.running = true;

        Qt.callLater(() => {
            searchField.forceActiveFocus();
        });
    }

    function close(): void {
        root.visible = false;
    }

    function clearAll(): void {
        clearProcess.running = true;
    }

    function parseEntries(text: string): void {
        const trimmed = text.trim();

        if (trimmed === "") {
            root.entries = [];
            root.filteredEntries = [];
            root.selectedIndex = -1;
            return;
        }

        const lines = trimmed.split("\n").filter(line => line.trim() !== "");

        const parsedEntries = [];

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split("\t");

            const raw = parts[0] || "";
            const display = parts[1] || "";
            const imagePath = parts[2] || "";

            const entry = {
                raw: raw,
                display: display,
                imagePath: imagePath,
                isImage: imagePath !== ""
            };

            // Google puts the image URL immediately after the image.
            if (entry.isImage && i + 1 < lines.length) {
                const nextParts = lines[i + 1].split("\t");

                const nextDisplay = nextParts[1] || "";

                if (nextDisplay.includes("\0")) {
                    i++;
                }
            }

            parsedEntries.push(entry);
        }

        root.entries = parsedEntries;
        root.filterEntries();
    }
    function filterEntries(): void {
        const query = searchField.text.toLowerCase().trim();

        if (query === "") {
            root.filteredEntries = root.entries;
        } else {
            root.filteredEntries = root.entries.filter(entry => entry.display.toLowerCase().includes(query));
        }

        root.selectedIndex = root.filteredEntries.length > 0 ? 0 : -1;

        Qt.callLater(() => {
            clipboardList.positionViewAtBeginning();
        });
    }

    function moveSelection(amount: int): void {
        const count = root.filteredEntries.length;

        if (count === 0) {
            root.selectedIndex = -1;
            return;
        }

        root.selectedIndex = Math.max(0, Math.min(count - 1, root.selectedIndex + amount));

        clipboardList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function selectCurrent(): void {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.filteredEntries.length)
            return;

        const entry = root.filteredEntries[root.selectedIndex];

        decodeProcess.selectedEntry = entry.raw;

        decodeProcess.running = true;
    }

    function deleteCurrent(): void {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.filteredEntries.length)
            return;

        const entry = root.filteredEntries[root.selectedIndex];

        deleteProcess.selectedEntry = entry.raw;

        deleteProcess.selectedId = entry.raw.split(/\s+/)[0];

        deleteProcess.running = true;
    }

    Rectangle {
        id: panel
        width: 520
        height: 560

        anchors.centerIn: parent

        radius: 18

        color: Theme.background

        border.width: 1
        border.color: Theme.accent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16

            spacing: 10

            // Header
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Clipboard"

                    color: Theme.text

                    font.pixelSize: 21
                    font.weight: Font.Medium
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: clearText.width + 20
                    height: 30

                    radius: 15

                    color: clearMouse.containsMouse ? Theme.foreground.alpha(0.08) : "transparent"

                    Text {
                        id: clearText

                        anchors.centerIn: parent

                        text: "Clear All"

                        color: Theme.textMuted

                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: clearMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: {
                            root.clearAll();
                        }
                    }
                }
            }

            // Search
            TextField {
                id: searchField

                Layout.fillWidth: true
                Layout.preferredHeight: 46

                placeholderText: "Search clipboard..."

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
                    root.filterEntries();
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) {
                        root.moveSelection(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.moveSelection(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.selectCurrent();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete) {
                        root.deleteCurrent();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    }
                }
            }

            // List
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: clipboardList

                    anchors.fill: parent

                    clip: true

                    spacing: 4

                    model: root.filteredEntries

                    delegate: Rectangle {
                        id: delegateRoot

                        required property int index
                        required property var modelData

                        width: clipboardList.width

                        height: modelData.isImage ? 130 : 52

                        radius: 10

                        color: index === root.selectedIndex ? Theme.accent.alpha(0.15) : clipboardMouse.containsMouse ? Theme.foreground.alpha(0.06) : "transparent"

                        // Image preview
                        Image {
                            id: imagePreview

                            visible: modelData.isImage

                            anchors.centerIn: parent

                            anchors.leftMargin: 8

                            anchors.top: parent.top

                            anchors.bottom: parent.bottom

                            width: 200

                            source: modelData.imagePath !== "" ? "file://" + modelData.imagePath : ""

                            fillMode: Image.PreserveAspectFit

                            asynchronous: true

                            cache: true

                            sourceSize.width: 320
                            sourceSize.height: 240
                        }

                        // Text
                        Text {
                            id: entryText

                            visible: !modelData.isImage
                            anchors.left: parent.left

                            anchors.leftMargin: 14

                            anchors.right: deleteButton.left

                            anchors.rightMargin: 8

                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData.display

                            color: index === root.selectedIndex ? Theme.accent : Theme.text

                            font.pixelSize: modelData.isImage ? 12 : 13

                            elide: Text.ElideRight

                            maximumLineCount: 1
                        }

                        // Normal row mouse area
                        MouseArea {
                            id: clipboardMouse

                            anchors.left: parent.left

                            anchors.top: parent.top

                            anchors.bottom: parent.bottom

                            anchors.right: deleteButton.left

                            hoverEnabled: true

                            onEntered: {
                                root.selectedIndex = index;
                            }

                            onClicked: {
                                root.selectedIndex = index;

                                root.selectCurrent();
                            }
                        }

                        // Delete button
                        Rectangle {
                            id: deleteButton

                            anchors.right: parent.right

                            anchors.rightMargin: 8

                            anchors.verticalCenter: parent.verticalCenter

                            width: 30
                            height: 30

                            radius: 15

                            color: deleteMouse.containsMouse ? Theme.foreground.alpha(0.1) : "transparent"

                            Text {
                                anchors.centerIn: parent

                                text: "×"

                                color: Theme.textMuted

                                font.pixelSize: 18
                            }

                            MouseArea {
                                id: deleteMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    deleteProcess.selectedEntry = modelData.raw;

                                    deleteProcess.selectedId = modelData.raw.split(/\s+/)[0];

                                    deleteProcess.running = true;
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible: root.filteredEntries.length === 0

                    text: root.entries.length === 0 ? "Clipboard is empty" : "No matches"

                    color: Theme.textMuted

                    font.pixelSize: 14
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42

                radius: 10

                color: Theme.surface

                Text {
                    anchors.centerIn: parent

                    text: "↑ ↓ Navigate   Enter Select   " + "Delete Remove   Esc Close"

                    color: Theme.textMuted

                    font.pixelSize: 10
                }
            }
        }
    }
}
