import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "EmojiLogic.js" as Logic

Item {
    id: backend

    property string emojiListPath:
        Quickshell.env("HOME") + "/.cache/quickshell/emojis.json"

    property string recentsCachePath:
        Quickshell.env("HOME") +
        "/.local/state/quickshell/rice/recent_emojis.json"

    property var allItems: []
    property var filteredItems: []
    property var recentItems: []

    property var pendingRecents: []

    property string selectionBuffer: ""
    property string searchText: ""
    property string currentCategory: "Recents"
    property string currentEmojiName: ""

    property var categories: ["Recents", "All"]

    signal openMenuRequested()
    signal closeMenuRequested()

    onCurrentCategoryChanged: triggerSearch()
    onSearchTextChanged: triggerSearch()

    function triggerSearch(): void {
        const query = searchText.trim()

        let items

        if (query !== "" || currentCategory === "All")
            items = allItems
        else
            items = recentItems

        filteredItems =
            query !== ""
                ? Logic.filterEmojis(items, query)
                : items

        if (filteredItems.length === 0)
            currentEmojiName = ""
        else
            currentEmojiName = filteredItems[0].display
    }

    function processSelection(emoji: string, isShift: bool): void {
        pendingRecents.push(emoji)

        if (isShift) {
            selectionBuffer += emoji
            return
        }

        const result = selectionBuffer + emoji

        selectionBuffer = ""

        copyProcess.selectedEmoji = result
        copyProcess.running = true

        closeMenuRequested()
    }

    function commitRecents(): void {
        if (pendingRecents.length === 0)
            return

        let updated = recentItems

        for (const emoji of pendingRecents) {
            updated = Logic.updateRecents(
                emoji,
                allItems,
                updated
            )
        }

        recentItems = updated
        pendingRecents = []

        saveRecentsProcess.running = true
    }

    function clearRecents(): void {
        recentItems = []
        filteredItems = []

        saveRecentsProcess.running = true

        triggerSearch()
    }

    function cycleCategory(): void {
        const index =
            categories.indexOf(currentCategory)

        currentCategory =
            categories[
                (index + 1) % categories.length
            ]
    }

    // Download/update emoji database
    Process {
        id: updateEmojisProcess

        command: [
            "bash",
            Quickshell.shellPath(
                "scripts/download_emojis.sh"
            )
        ]

        Component.onCompleted: {
            running = true
        }

        onRunningChanged: {
            if (!running)
                loadEmojisProcess.running = true
        }
    }

    // Load emoji database
    Process {
        id: loadEmojisProcess

        command: [
            "cat",
            backend.emojiListPath
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    backend.allItems =
                        Logic.parseEmojiJson(this.text)

                    loadRecentsProcess.running = true
                } catch (error) {
                    console.error(
                        "Failed to parse emojis:",
                        error
                    )
                }
            }
        }
    }

    // Load recents
    Process {
        id: loadRecentsProcess

        command: [
            "cat",
            backend.recentsCachePath
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved =
                        JSON.parse(this.text)

                    if (!Array.isArray(saved)) {
                        backend.triggerSearch()
                        return
                    }

                    backend.recentItems =
                        saved
                            .map(emoji =>
                                backend.allItems.find(
                                    item =>
                                        item.emoji === emoji
                                )
                            )
                            .filter(Boolean)

                } catch (error) {
                    backend.recentItems = []
                }

                backend.triggerSearch()
            }

        }

        onExited: {
            backend.triggerSearch()
        }
    }

    // Save recents
    Process {
        id: saveRecentsProcess

        property string jsonString:
            JSON.stringify(
                backend.recentItems.map(
                    item => item.emoji
                )
            )

        command: [
            "bash",
            "-c",
            "mkdir -p \"$(dirname \"$1\")\" && " +
            "printf '%s' \"$2\" > \"$1\"",
            "_",
            backend.recentsCachePath,
            jsonString
        ]
    }

    // Copy selected emoji
    Process {
        id: copyProcess

        property string selectedEmoji: ""

        command: [
            "bash",
            "-c",
            "printf '%s' \"$1\" | wl-copy && " +
            "wtype \"$1\"",
            "_",
            selectedEmoji
        ]

        onExited: {
            selectedEmoji = ""
        }
    }

    IpcHandler {
        target: "emoji"

        function toggle(): void {
            backend.openMenuRequested()
        }
    }
}
