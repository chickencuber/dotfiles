pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "../components/"
import "../singletons/"
import "../services/wms/"

Scope {
    id: root

    property string screenshotDir:
        Quickshell.env("HOME") + "/Pictures/Screenshots"

    property int selectedIndex: 0

    property list<string> options: [
        "Active Monitor",
        "Active Window",
        "Monitor",
        "Window",
        "Region"
    ]

    property bool pendingScreenshot: false
    property int pendingMode: WM.ActiveMonitor

    // =========================================================
    // SCREENSHOT
    // =========================================================

    function takeScreenshot(): void {
        if (root.pendingScreenshot)
            return

        root.pendingScreenshot = true
        root.pendingMode = root.selectedIndex
        panel.open = false
    }

    function runScreenshot(): void {
        ShellContext.wm.screenshot(
            root.pendingMode,
            root.screenshotDir
        )

        root.pendingScreenshot = false
    }

    // =========================================================
    // FLOATING PANEL
    // =========================================================

    FloatingPanel {
        id: panel

        ipc: "screenshot"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        background: "transparent"

        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade

        onOpenChanged: {
            if (open) {
                root.selectedIndex = 0
                root.pendingScreenshot = false
            }
        }

        onAnimationFinished: opening => {
            if (opening) {
                Qt.callLater(() => keyboardFocus.forceActiveFocus())
            } else if (root.pendingScreenshot) {
                root.runScreenshot()
            }
        }

        FocusScope {
            id: keyboardFocus

            anchors.fill: parent
            focus: true

            Keys.onLeftPressed: event => {
                root.selectedIndex =
                    (root.selectedIndex - 1 + root.options.length) %
                    root.options.length

                event.accepted = true
            }

            Keys.onRightPressed: event => {
                root.selectedIndex =
                    (root.selectedIndex + 1) % root.options.length

                event.accepted = true
            }

            Keys.onReturnPressed: event => {
                root.takeScreenshot()
                event.accepted = true
            }

            Keys.onEscapePressed: event => {
                panel.open = false
                event.accepted = true
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }

                height: 70
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent

                    width: optionsRow.width + 12
                    height: 42

                    radius: height / 2

                    color: Theme.background.alpha(0.96)

                    border.width: 2
                    border.color: Theme.accent

                    Row {
                        id: optionsRow

                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: root.options

                            delegate: Rectangle {
                                required property int index
                                required property string modelData

                                width: optionText.width + 24
                                height: 32

                                radius: 16
                                color: "transparent"

                                Text {
                                    id: optionText

                                    anchors.centerIn: parent

                                    text: modelData

                                    color: index === root.selectedIndex
                                        ? Theme.accent
                                        : Theme.text

                                    font.family: Theme.font
                                    font.pixelSize: 16
                                    font.bold: index === root.selectedIndex

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {
                                        root.selectedIndex = index
                                        keyboardFocus.forceActiveFocus()
                                    }

                                    onDoubleClicked: {
                                        root.selectedIndex = index
                                        root.takeScreenshot()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

