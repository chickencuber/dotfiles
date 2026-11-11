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

    property alias visible: panel.open

    // =========================================================
    // CLIPBOARD STATE
    // =========================================================

    property var entries: []
    property var filteredEntries: []

    property var pinnedEntries: []
    property var filteredPinnedEntries: []

    property int selectedIndex: -1

    readonly property string statePath:
        Quickshell.env("HOME") + "/.local/state/quickshell/rice"

    readonly property string pinnedPath:
        statePath + "/pinned-clipboard.json"

    readonly property string pinnedDataPath:
        statePath + "/pinned-clipboard"

    // =========================================================
    // PINNED STORAGE
    // =========================================================

    FileView {
        id: pinnedFile

        path: root.pinnedPath
        watchChanges: false

        onLoaded: {
            try {
                const data = JSON.parse(text())
                root.pinnedEntries = Array.isArray(data) ? data : []
            } catch (error) {
                root.pinnedEntries = []
            }

            root.filterEntries()
        }
    }

    function savePinned(): void {
        pinnedFile.setText(JSON.stringify(root.pinnedEntries, null, 2))
    }

    // =========================================================
    // CLEAR HISTORY
    // =========================================================

    Process {
        id: clearProcess

        command: ["bash", "-c", "cliphist wipe"]

        onExited: {
            root.entries = []
            root.filteredEntries = []
            root.selectedIndex = -1
            root.filterEntries()
        }
    }

    // =========================================================
    // LIST HISTORY
    // =========================================================

    Process {
        id: listProcess

        command: [
            "bash",
            Quickshell.shellPath("scripts/cliphist-visual.sh")
        ]

        stdout: StdioCollector {
            onStreamFinished: root.parseEntries(text)
        }
    }

    // =========================================================
    // SELECT HISTORY ENTRY
    // =========================================================

    Process {
        id: decodeProcess

        property string selectedEntry: ""

        command: [
            "bash",
            "-c",
            "printf '%s' \"$1\" | cliphist decode | wl-copy",
            "_",
            selectedEntry
        ]

        onExited: {
            selectedEntry = ""
            root.close()
        }
    }

    // =========================================================
    // DELETE HISTORY ENTRY
    // =========================================================

    Process {
        id: deleteProcess

        property string selectedEntry: ""
        property string selectedId: ""

        command: [
            "bash",
            "-c",
            "printf '%s' \"$1\" | cliphist delete && rm -f /tmp/cliphist/\"$2\".*",
            "_",
            selectedEntry,
            selectedId
        ]

        onExited: {
            selectedEntry = ""
            selectedId = ""

            listProcess.running = true
        }
    }

    // =========================================================
    // CREATE PINNED COPY
    // =========================================================

    Process {
        id: pinProcess

        property string selectedEntry: ""
        property string pinId: ""
        property string outputPath: ""
        property var pendingEntry: null

        command: [
            "bash",
            "-c",
            "mkdir -p \"$1\" && printf '%s' \"$2\" | cliphist decode > \"$3\"",
            "_",
            root.pinnedDataPath,
            selectedEntry,
            outputPath
        ]

        onExited: {
            if (pendingEntry !== null) {
                const entry = pendingEntry

                const pinned = {
                    id: pinId,
                    display: entry.display,
                    isImage: entry.isImage,
                    filePath: outputPath
                }

                root.pinnedEntries = root.pinnedEntries.concat([pinned])

                root.savePinned()
                root.filterEntries()
            }

            selectedEntry = ""
            pinId = ""
            outputPath = ""
            pendingEntry = null
        }
    }

    // =========================================================
    // REMOVE PINNED ENTRY
    // =========================================================

    Process {
        id: unpinProcess

        property string filePath: ""

        command: ["bash", "-c", "rm -f -- \"$1\"", "_", filePath]

        onExited: filePath = ""
    }

    // =========================================================
    // SELECT PINNED ENTRY
    // =========================================================

    Process {
        id: pinnedSelectProcess

        property string filePath: ""
        property bool isImage: false

        command: [
            "bash",
            "-c",
            "if [ \"$2\" = \"true\" ]; then " +
            "wl-copy --type image/png < \"$1\"; " +
            "else wl-copy < \"$1\"; fi",
            "_",
            filePath,
            isImage ? "true" : "false"
        ]

        onExited: {
            filePath = ""
            isImage = false

            root.close()
        }
    }

    // =========================================================
    // OPEN / CLOSE
    // =========================================================

    function open(): void {
        panel.open = true
    }

    function close(): void {
        panel.open = false
    }

    function clearAll(): void {
        clearProcess.running = true
    }

    // =========================================================
    // PARSE CLIPHIST
    // =========================================================

    function parseEntries(text: string): void {
        const trimmed = text.trim()

        if (trimmed === "") {
            root.entries = []
            root.filteredEntries = []
            root.selectedIndex = -1
            root.filterEntries()
            return
        }

        const lines = trimmed
            .split("\n")
            .filter(line => line.trim() !== "")

        const parsedEntries = []

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split("\t")

            const raw = parts[0] || ""
            const display = parts[1] || ""
            const imagePath = parts[2] || ""

            const entry = {
                raw: raw,
                display: display,
                imagePath: imagePath,
                isImage: imagePath !== ""
            }

            // Google puts the image URL immediately after the image.
            if (entry.isImage && i + 1 < lines.length) {
                const nextParts = lines[i + 1].split("\t")
                const nextDisplay = nextParts[1] || ""

                if (nextDisplay.includes("\0"))
                    i++
            }

            parsedEntries.push(entry)
        }

        root.entries = parsedEntries
        root.filterEntries()
    }

    // =========================================================
    // PIN HELPERS
    // =========================================================

    function isPinned(entry): bool {
        if (!entry)
            return false

        for (const pinned of root.pinnedEntries) {
            if (pinned.display === entry.display &&
                pinned.isImage === entry.isImage) {
                return true
            }
        }

        return false
    }

    function togglePin(entry): void {
        if (!entry)
            return

        if (root.isPinned(entry)) {
            for (let i = 0; i < root.pinnedEntries.length; i++) {
                const pinned = root.pinnedEntries[i]

                if (pinned.display === entry.display &&
                    pinned.isImage === entry.isImage) {
                    root.removePinned(pinned)
                    return
                }
            }

            return
        }

        const pinId =
            Date.now().toString() + "-" +
            Math.floor(Math.random() * 1000000).toString()

        const outputPath = root.pinnedDataPath + "/" + pinId

        pinProcess.selectedEntry = entry.raw
        pinProcess.pinId = pinId
        pinProcess.outputPath = outputPath
        pinProcess.pendingEntry = entry

        pinProcess.running = true
    }

    function removePinned(entry): void {
        if (!entry)
            return

        const remaining = []

        for (const pinned of root.pinnedEntries) {
            if (pinned.id !== entry.id)
                remaining.push(pinned)
        }

        root.pinnedEntries = remaining

        root.savePinned()
        root.filterEntries()

        unpinProcess.filePath = entry.filePath
        unpinProcess.running = true
    }

    // =========================================================
    // FILTERING
    // =========================================================

    function filterEntries(): void {
        const query = searchField.text.toLowerCase().trim()

        if (query === "") {
            root.filteredPinnedEntries = root.pinnedEntries
        } else {
            root.filteredPinnedEntries =
                root.pinnedEntries.filter(entry =>
                    entry.display.toLowerCase().includes(query)
                )
        }

        // Normal history excludes pinned entries.
        let normalEntries = []

        for (const entry of root.entries) {
            if (!root.isPinned(entry))
                normalEntries.push(entry)
        }

        if (query === "") {
            root.filteredEntries = normalEntries
        } else {
            root.filteredEntries =
                normalEntries.filter(entry =>
                    entry.display.toLowerCase().includes(query)
                )
        }

        root.selectedIndex =
            root.filteredEntries.length > 0 ? 0 : -1

        Qt.callLater(() => {
            clipboardList.positionViewAtBeginning()
        })
    }

    // =========================================================
    // KEYBOARD NAVIGATION
    // =========================================================

    function moveSelection(amount: int): void {
        const count = root.filteredEntries.length

        if (count === 0) {
            root.selectedIndex = -1
            return
        }

        root.selectedIndex = Math.max(
            0,
            Math.min(count - 1, root.selectedIndex + amount)
        )

        clipboardList.positionViewAtIndex(
            root.selectedIndex,
            ListView.Contain
        )
    }

    function selectCurrent(): void {
        if (root.selectedIndex < 0 ||
            root.selectedIndex >= root.filteredEntries.length) {
            return
        }

        const entry = root.filteredEntries[root.selectedIndex]

        decodeProcess.selectedEntry = entry.raw
        decodeProcess.running = true
    }

    function deleteCurrent(): void {
        if (root.selectedIndex < 0 ||
            root.selectedIndex >= root.filteredEntries.length) {
            return
        }

        const entry = root.filteredEntries[root.selectedIndex]

        deleteProcess.selectedEntry = entry.raw
        deleteProcess.selectedId = entry.raw.split(/\s+/)[0]

        deleteProcess.running = true
    }

    // =========================================================
    // FLOATING PANEL
    // =========================================================

    FloatingPanel {
        id: panel

        ipc: "clipboard"

        width: 520
        height: 620

        origin: FloatingPanel.Center

        background: "transparent"

        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade

        // IPC and direct QML opens both come through here.
        onAnimationFinished: {
            if (open) {
                searchField.text = ""
                listProcess.running = true

                Qt.callLater(() => {
                    searchField.forceActiveFocus()
                })
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

                // =================================================
                // HEADER
                // =================================================

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Clipboard"

                        color: Theme.text

                        font.family: Theme.font
                        font.pixelSize: 21
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        width: clearText.width + 20
                        height: 30

                        radius: 15

                        color: clearMouse.containsMouse
                            ? Theme.foreground.alpha(0.08)
                            : "transparent"

                        Text {
                            id: clearText

                            anchors.centerIn: parent

                            text: "Clear All"

                            color: Theme.textMuted

                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: clearMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: root.clearAll()
                        }
                    }
                }

                // =================================================
                // SEARCH
                // =================================================

                TextField {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    placeholderText: "Search clipboard..."

                    color: Theme.text
                    placeholderTextColor: Theme.textMuted

                    font.family: Theme.font
                    font.pixelSize: 14

                    background: Rectangle {
                        radius: 12

                        color: searchField.activeFocus
                            ? Theme.background.alpha(0.65)
                            : Theme.surface

                        border.width: searchField.activeFocus ? 2 : 1

                        border.color: searchField.activeFocus
                            ? Theme.accent
                            : Theme.foreground.alpha(0.1)
                    }

                    onTextChanged: root.filterEntries()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            root.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1)
                            event.accepted = true
                        } else if (
                            event.key === Qt.Key_Return ||
                            event.key === Qt.Key_Enter
                        ) {
                            root.selectCurrent()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Delete) {
                            root.deleteCurrent()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                        }
                    }
                }

                // =================================================
                // PINNED ENTRIES
                // =================================================

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 5

                    visible: root.filteredPinnedEntries.length > 0

                    Text {
                        Layout.fillWidth: true

                        text: "Pinned"

                        color: Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    Repeater {
                        model: root.filteredPinnedEntries

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: modelData.isImage ? 90 : 44

                            radius: 10

                            color: pinnedMouse.containsMouse
                                ? Theme.foreground.alpha(0.06)
                                : "transparent"

                            Image {
                                visible: modelData.isImage

                                anchors.left: parent.left
                                anchors.leftMargin: 8

                                anchors.top: parent.top
                                anchors.bottom: parent.bottom

                                width: 120

                                source: modelData.isImage
                                    ? "file://" + modelData.filePath
                                    : ""

                                fillMode: Image.PreserveAspectFit

                                asynchronous: true
                                cache: false

                                sourceSize.width: 240
                                sourceSize.height: 180
                            }

                            Text {
                                visible: !modelData.isImage

                                anchors.left: parent.left
                                anchors.leftMargin: 14

                                anchors.right: unpinButton.left
                                anchors.rightMargin: 8

                                anchors.verticalCenter: parent.verticalCenter

                                text: modelData.display

                                color: Theme.text

                                font.family: Theme.font
                                font.pixelSize: 13

                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                visible: modelData.isImage

                                anchors.left: parent.left
                                anchors.leftMargin: 138

                                anchors.right: unpinButton.left
                                anchors.rightMargin: 8

                                anchors.verticalCenter: parent.verticalCenter

                                text: modelData.display

                                color: Theme.text

                                font.family: Theme.font
                                font.pixelSize: 12

                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            MouseArea {
                                id: pinnedMouse

                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: unpinButton.left

                                hoverEnabled: true

                                onClicked: {
                                    pinnedSelectProcess.filePath = modelData.filePath
                                    pinnedSelectProcess.isImage = modelData.isImage
                                    pinnedSelectProcess.running = true
                                }
                            }

                            Rectangle {
                                id: unpinButton

                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter

                                width: 30
                                height: 30

                                radius: 15

                                color: unpinMouse.containsMouse
                                    ? Theme.foreground.alpha(0.1)
                                    : "transparent"

                                Icon {
                                    anchors.centerIn: parent

                                    name: "push_pin"
                                    filled: true

                                    iconColor: Theme.accent
                                    width: 18
                                    height: width
                                }

                                MouseArea {
                                    id: unpinMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: root.removePinned(modelData)
                                }
                            }
                        }
                    }
                }

                // =================================================
                // NORMAL HISTORY
                // =================================================

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

                            color: index === root.selectedIndex
                                ? Theme.accent.alpha(0.15)
                                : clipboardMouse.containsMouse
                                    ? Theme.foreground.alpha(0.06)
                                    : "transparent"

                            Image {
                                id: imagePreview

                                visible: modelData.isImage

                                anchors.centerIn: parent

                                anchors.top: parent.top
                                anchors.bottom: parent.bottom

                                width: 200

                                source: modelData.imagePath !== ""
                                    ? "file://" + modelData.imagePath
                                    : ""

                                fillMode: Image.PreserveAspectFit

                                asynchronous: true
                                cache: true

                                sourceSize.width: 320
                                sourceSize.height: 240
                            }

                            Text {
                                visible: !modelData.isImage

                                anchors.left: parent.left
                                anchors.leftMargin: 14

                                anchors.right: pinButton.left
                                anchors.rightMargin: 8

                                anchors.verticalCenter: parent.verticalCenter

                                text: modelData.display

                                color: index === root.selectedIndex
                                    ? Theme.accent
                                    : Theme.text

                                font.family: Theme.font
                                font.pixelSize: 13

                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            MouseArea {
                                id: clipboardMouse

                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: pinButton.left

                                hoverEnabled: true

                                onEntered: root.selectedIndex = index

                                onClicked: {
                                    root.selectedIndex = index
                                    root.selectCurrent()
                                }
                            }

                            Rectangle {
                                id: pinButton

                                anchors.right: deleteButton.left
                                anchors.rightMargin: 2

                                anchors.verticalCenter: parent.verticalCenter

                                width: 30
                                height: 30

                                radius: 15

                                color: pinMouse.containsMouse
                                    ? Theme.foreground.alpha(0.1)
                                    : "transparent"

                                Icon {
                                    anchors.centerIn: parent

                                    name: "add"

                                    iconColor: Theme.textMuted
                                    width: 18
                                    height: width
                                }

                                MouseArea {
                                    id: pinMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: root.togglePin(modelData)
                                }
                            }

                            Rectangle {
                                id: deleteButton

                                anchors.right: parent.right
                                anchors.rightMargin: 8

                                anchors.verticalCenter: parent.verticalCenter

                                width: 30
                                height: 30

                                radius: 15

                                color: deleteMouse.containsMouse
                                    ? Theme.foreground.alpha(0.1)
                                    : "transparent"

                                Icon {
                                    anchors.centerIn: parent

                                    name: "delete"

                                    iconColor: Theme.textMuted
                                    width: 18
                                    height: width
                                }

                                MouseArea {
                                    id: deleteMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: {
                                        deleteProcess.selectedEntry = modelData.raw
                                        deleteProcess.selectedId = modelData.raw.split(/\s+/)[0]
                                        deleteProcess.running = true
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        visible:
                            root.filteredEntries.length === 0 &&
                            root.filteredPinnedEntries.length === 0

                        text:
                            root.entries.length === 0 &&
                            root.pinnedEntries.length === 0
                                ? "Clipboard is empty"
                                : "No matches"

                        color: Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                }

                // =================================================
                // FOOTER
                // =================================================

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    radius: 10
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent

                        text: "↑ ↓ Navigate   Enter Select   Delete Remove   Esc Close"

                        color: Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
