pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import "../components/"
import "../services/"
import "../singletons/"

Scope {
    id: root

    property int selectedIndex: -1

    function applySelected(): void {
        if (selectedIndex < 0 ||
            selectedIndex >= Wallpaper.wallpapers.length)
            return

        Wallpaper.setWallpaper(Wallpaper.wallpapers[selectedIndex])
        wallpaperPanel.open = false
    }

    FloatingPanel {
        id: wallpaperPanel

        ipc: "wallpaper"

        height: 210
        on_open.type: PanelAnimation.Bottom
        on_close.type: PanelAnimation.Bottom

        anchors {
            bottom: true
            left: true
            right: true
        }

        background: Theme.background.alpha(0.96)

        onAnimationFinished: opening => {
            if (!opening)
                return

            root.selectedIndex = -1
            Wallpaper.refresh()

            Qt.callLater(() => keyboardFocus.forceActiveFocus())
        }

        FocusScope {
            id: keyboardFocus

            anchors.fill: parent
            focus: true

            Keys.onLeftPressed: event => {
                if (Wallpaper.wallpapers.length === 0)
                    return

                root.selectedIndex = root.selectedIndex <= 0
                    ? 0
                    : root.selectedIndex - 1

                wallpapersList.positionViewAtIndex(
                    root.selectedIndex,
                    ListView.Contain
                )

                event.accepted = true
            }

            Keys.onRightPressed: event => {
                if (Wallpaper.wallpapers.length === 0)
                    return

                root.selectedIndex = root.selectedIndex < 0
                    ? 0
                    : Math.min(
                        root.selectedIndex + 1,
                        Wallpaper.wallpapers.length - 1
                    )

                wallpapersList.positionViewAtIndex(
                    root.selectedIndex,
                    ListView.Contain
                )

                event.accepted = true
            }

            Keys.onReturnPressed: event => {
                root.applySelected()
                event.accepted = true
            }

            Keys.onEscapePressed: event => {
                wallpaperPanel.open = false
                event.accepted = true
            }

            // HEADER

            Text {
                id: header

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 10
                    leftMargin: 16
                    rightMargin: 16
                }

                height: 24

                text: "Wallpapers"
                color: Theme.text

                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // WALLPAPER LIST

            ListView {
                id: wallpapersList

                anchors {
                    top: header.bottom
                    bottom: statusBar.top
                    left: parent.left
                    right: parent.right
                    margins: 8
                }

                orientation: ListView.Horizontal
                spacing: 10
                clip: true

                model: Wallpaper.wallpapers
                currentIndex: root.selectedIndex

                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: wallpaperItem

                    required property int index
                    required property string modelData

                    width: 180
                    height: 120

                    readonly property string wallpaperPath:
                        Wallpaper.wallDir + "/" + modelData

                    readonly property bool isCurrent:
                        Wallpaper.currentWallpaper === wallpaperPath

                    Rectangle {
                        anchors.fill: parent

                        radius: 10

                        color: index === root.selectedIndex
                            ? Theme.bgSelected
                            : Theme.surface

                        border.width: index === root.selectedIndex ||
                            wallpaperItem.isCurrent ? 2 : 0

                        border.color: wallpaperItem.isCurrent
                            ? Theme.accent
                            : Theme.text

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true

                            sourceComponent: wallpaperItem.modelData
                                .toLowerCase().endsWith(".gif")
                                ? animatedPreview
                                : staticPreview

                            Component {
                                id: animatedPreview

                                AnimatedImage {
                                    anchors.fill: parent

                                    source: "file://" + wallpaperItem.wallpaperPath

                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    playing: true
                                    loops: Animation.Infinite
                                }
                            }

                            Component {
                                id: staticPreview

                                Image {
                                    anchors.fill: parent

                                    source: "file://" + wallpaperItem.wallpaperPath

                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }
                            }
                        }

                        // FILENAME

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 4
                            }

                            height: 26
                            radius: 6

                            color: Theme.background.alpha(0.8)

                            Text {
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 8
                                }

                                text: wallpaperItem.modelData

                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 10

                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.selectedIndex = wallpaperItem.index
                                keyboardFocus.forceActiveFocus()
                            }

                            onDoubleClicked: {
                                root.selectedIndex = wallpaperItem.index
                                root.applySelected()
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible: Wallpaper.wallpapers.length === 0

                    text: "No wallpapers found"
                    color: Theme.textMuted

                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }

            // STATUS BAR

            Rectangle {
                id: statusBar

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 38
                color: Theme.surface

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.selectedIndex >= 0 &&
                            root.selectedIndex < Wallpaper.wallpapers.length
                            ? Wallpaper.wallpapers[root.selectedIndex]
                            : "Select a wallpaper"

                        color: root.selectedIndex >= 0
                            ? Theme.text
                            : Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
