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

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            root.close()
        }
    }

    property var windows: []
    property var filteredWindows: []
    property int selectedIndex: -1

    IpcHandler {
        target: "windows"

        function toggle(): void {
            if (root.visible)
                root.close()
            else
                root.open()
        }
    }

    Process {
        id: clientProcess

        command: ["hyprctl", "-j", "clients"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseWindows(this.text)
            }
        }
    }

    Process {
        id: focusProcess

        onExited: {
            root.close()
        }
    }

    function open(): void {
        root.visible = true

        searchField.text = ""

        clientProcess.running = true

        Qt.callLater(() => {
            searchField.forceActiveFocus()
        })
    }

    function close(): void {
        root.visible = false
    }

    function parseWindows(text: string): void {
        try {
            const clients = JSON.parse(text)

            root.windows = clients
                .filter(client => client.address && client.title)
                .map(client => ({
                    address: client.address,
                    workspace: client.workspace
                        ? client.workspace.name
                        : "",
                    title: client.title,
                    className: client.class || "",
                    appId: client.class || ""
                }))

            root.filterWindows()
        } catch (error) {
            console.log(
                "Failed to parse Hyprland clients:",
                error
            )

            root.windows = []
            root.filteredWindows = []
            root.selectedIndex = -1
        }
    }

    function filterWindows(): void {
        const query =
            searchField.text.toLowerCase().trim()

        if (query === "") {
            root.filteredWindows = root.windows
        } else {
            root.filteredWindows =
                root.windows.filter(window =>
                    window.title
                        .toLowerCase()
                        .includes(query) ||
                    window.className
                        .toLowerCase()
                        .includes(query) ||
                    window.workspace
                        .toLowerCase()
                        .includes(query)
                )
        }

        root.selectedIndex =
            root.filteredWindows.length > 0 ? 0 : -1

        Qt.callLater(() => {
            windowList.positionViewAtBeginning()
        })
    }

    function moveSelection(amount: int): void {
        const count = root.filteredWindows.length

        if (count === 0) {
            root.selectedIndex = -1
            return
        }

        root.selectedIndex = Math.max(
            0,
            Math.min(
                count - 1,
                root.selectedIndex + amount
            )
        )

        windowList.positionViewAtIndex(
            root.selectedIndex,
            ListView.Contain
        )
    }

    function focusCurrent(): void {
        if (root.selectedIndex < 0)
            return

        const selected =
            root.filteredWindows[root.selectedIndex]

        if (!selected)
            return

        console.log("Focusing:", selected.address)

        focusProcess.command = [
            "hyprctl",
            "dispatch",
            "hl.dsp.focus({window=\"address:" +
            selected.address +
            "\"})"
        ]

        focusProcess.running = true
    }

    Rectangle {
        id: panel

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

            TextField {
                id: searchField

                Layout.fillWidth: true
                Layout.preferredHeight: 46

                placeholderText: "Search windows..."

                color: Theme.text
                placeholderTextColor: Theme.textMuted

                font.pixelSize: 14

                background: Rectangle {
                    radius: 12

                    color: searchField.activeFocus
                        ? Theme.background.alpha(0.65)
                        : Theme.surface

                    border.width:
                        searchField.activeFocus ? 2 : 1

                    border.color:
                        searchField.activeFocus
                            ? Theme.accent
                            : Theme.foreground.alpha(0.1)
                }

                onTextChanged: {
                    root.filterWindows()
                }

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
                        root.focusCurrent()
                        event.accepted = true
                    } else if (
                        event.key === Qt.Key_Escape
                    ) {
                        root.close()
                        event.accepted = true
                    }
                }
            }

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

                        color:
                            index === root.selectedIndex
                                ? Theme.accent.alpha(0.15)
                                : windowMouse.containsMouse
                                    ? Theme.foreground.alpha(0.06)
                                    : "transparent"

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            spacing: 10

                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter

                                property var desktopEntry:
                                    DesktopEntries.byId(
                                        modelData.appId
                                    )

                                property string iconName:
                                    desktopEntry?.icon ?? ""

                                Image {
                                    anchors.fill: parent

                                    source:
                                        parent.iconName !== ""
                                            ? Quickshell.iconPath(
                                                parent.iconName
                                            )
                                            : ""

                                    fillMode:
                                        Image.PreserveAspectFit

                                    smooth: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment:
                                    Qt.AlignVCenter

                                text: modelData.title

                                color:
                                    index === root.selectedIndex
                                        ? Theme.accent
                                        : Theme.text

                                font.family:
                                    "JetBrainsMono Nerd Font Mono"

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
                                root.selectedIndex = index
                            }

                            onClicked: {
                                root.selectedIndex = index
                                root.focusCurrent()
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible:
                        root.filteredWindows.length === 0

                    text:
                        root.windows.length === 0
                            ? "No windows"
                            : "No matches"

                    color: Theme.textMuted

                    font.pixelSize: 14
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42

                radius: 10

                color: Theme.surface

                Text {
                    anchors.centerIn: parent

                    text:
                        "↑ ↓ Navigate   Enter Focus   Esc Close"

                    color: Theme.textMuted

                    font.pixelSize: 10
                }
            }
        }
    }
}
