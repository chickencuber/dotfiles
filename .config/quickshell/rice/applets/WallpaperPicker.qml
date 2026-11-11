
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Controls

import "../components/"
import "../services/"
import "../singletons/"

Scope {
    id: root

    property int selectedIndex: -1
    property bool waitingForApply: false

    function applySelected(): void {
        if (Wallpaper.applying ||
            selectedIndex < 0 ||
            selectedIndex >= Wallpaper.wallpapers.length)
            return

        waitingForApply = true
        Wallpaper.setWallpaper(Wallpaper.wallpapers[selectedIndex])
    }

    Connections {
        target: Wallpaper

        function onApplyingChanged(): void {
            if (!Wallpaper.applying && root.waitingForApply) {
                root.waitingForApply = false
                wallpaperPanel.open = false
            }
        }
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
                if (Wallpaper.applying || Wallpaper.wallpapers.length === 0)
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
                if (Wallpaper.applying || Wallpaper.wallpapers.length === 0)
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
                if (!Wallpaper.applying)
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

                text: Wallpaper.applying
                    ? "Applying wallpaper"
                    : "Wallpapers"

                color: Wallpaper.applying ? Theme.accent : Theme.text

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

                    Rectangle {
                        anchors.fill: parent

                        radius: 10

                        color: index === root.selectedIndex
                            ? Theme.bgSelected
                            : Theme.surface

                        border.width: index === root.selectedIndex ? 2 : 0
                        border.color: Theme.accent

                        opacity: Wallpaper.applying &&
                            index !== root.selectedIndex ? 0.35 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

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

                                    source: "file://" +
                                        Wallpaper.wallDir + "/" +
                                        wallpaperItem.modelData

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

                                    source: "file://" +
                                        Wallpaper.wallDir + "/" +
                                        wallpaperItem.modelData

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
                            visible: !Wallpaper.applying

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

                        // APPLYING OVERLAY

                        Rectangle {
                            anchors.fill: parent

                            radius: 10

                            visible: Wallpaper.applying &&
                                index === root.selectedIndex

                            color: Theme.background.alpha(0.88)

                            Column {
                                anchors.centerIn: parent
                                spacing: 7

                                BusyIndicator {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    width: 34
                                    height: 34

                                    running: Wallpaper.applying
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "APPLYING"
                                    color: Theme.accent

                                    font.family: Theme.font
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Wallpaper"
                                    color: Theme.textMuted

                                    font.family: Theme.font
                                    font.pixelSize: 10
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !Wallpaper.applying

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

                    BusyIndicator {
                        visible: Wallpaper.applying

                        width: 18
                        height: 18

                        running: Wallpaper.applying
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: Wallpaper.applying
                            ? "APPLYING WALLPAPER..."
                            : root.selectedIndex >= 0 &&
                                root.selectedIndex < Wallpaper.wallpapers.length
                            ? Wallpaper.wallpapers[root.selectedIndex]
                            : "Select a wallpaper"

                        color: Wallpaper.applying
                            ? Theme.accent
                            : root.selectedIndex >= 0
                            ? Theme.text
                            : Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 11
                        font.bold: Wallpaper.applying
                    }
                }
            }
        }
    }
}
