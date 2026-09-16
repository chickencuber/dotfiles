// wallpaper/WallpaperPicker.qml

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property string wallDir: Quickshell.env("HOME") + "/.config/hypr/walls"

    property string wallPath: Quickshell.env("HOME") + "/.config/hypr/wall"

    property string thumbnailPath: Quickshell.env("HOME") + "/.config/hypr/thumbnail.png"

    property string font: "JetBrainsMono Nerd Font Mono"

    property list<string> wallpapers: []

    property int selectedIndex: -1

    property bool applying: false

    // ------------------------------------------------------------------
    // IPC
    // ------------------------------------------------------------------

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            wallpaperPanel.visible = !wallpaperPanel.visible;

            if (wallpaperPanel.visible) {
                root.selectedIndex = -1;
                findWallpapers.running = true;

                Qt.callLater(() => {
                    keyboardFocus.forceActiveFocus();
                });
            }
        }
    }

    // ------------------------------------------------------------------
    // Find wallpapers
    // ------------------------------------------------------------------

    Process {
        id: findWallpapers

        command: ["find", root.wallDir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.gif", ")", "-printf", "%f\n"]

        stdout: StdioCollector {
            id: wallpaperOutput

            onStreamFinished: {
                const output = wallpaperOutput.text.trim();

                if (output === "") {
                    root.wallpapers = [];
                    return;
                }

                root.wallpapers = output.split("\n").filter(name => name !== "").sort((a, b) => a.localeCompare(b));

                // Don't automatically select anything.
                root.selectedIndex = -1;
            }
        }
    }

    // ------------------------------------------------------------------
    // Apply wallpaper
    // ------------------------------------------------------------------

    function applyWallpaper(name: string): void {
        if (root.applying)
            return;
        if (name === "")
            return;
        root.applying = true;

        copyWallpaper.command = ["cp", root.wallDir + "/" + name, root.wallPath];

        copyWallpaper.running = true;
    }

    Process {
        id: copyWallpaper

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.applying = false;
                return;
            }

            createThumbnail.running = true;
        }
    }

    Process {
        id: createThumbnail

        command: ["ffmpeg", "-y", "-i", root.wallPath, "-vf", "scale=200:-1", "-vframes", "1", root.thumbnailPath]

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.applying = false;
                return;
            }

            clearCache.running = true;
        }
    }

    Process {
        id: clearCache

        command: ["awww", "clear-cache"]

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.applying = false;
                return;
            }

            setWallpaper.running = true;
        }
    }

    Process {
        id: setWallpaper

        command: ["awww", "img", root.wallPath, "--transition-type", "fade", "--transition-duration", "1"]

        onExited: exitCode => {
            root.applying = false;
            wallpaperPanel.visible = false;
            event.accepted = true;
        }
    }

    // ------------------------------------------------------------------
    // Wallpaper picker
    // ------------------------------------------------------------------

    PanelWindow {

        exclusionMode: ExclusionMode.Ignore
        id: wallpaperPanel

        visible: false

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"

        // --------------------------------------------------------------
        // Keyboard focus
        // --------------------------------------------------------------

        MouseArea {
            anchors.fill: parent

            onClicked: {
                if (root.applying)
                    return;
                wallpaperPanel.visible = false;
                event.accepted = true;
            }
        }
        Rectangle {
            color: "transparent"
            height: 210
            width: parent.width
            anchors.bottom: parent.bottom
            FocusScope {
                id: keyboardFocus

                anchors.fill: parent

                focus: true

                Keys.onLeftPressed: event => {
                    if (root.applying)
                        return;
                    if (root.wallpapers.length === 0)
                        return;
                    if (root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                    } else if (root.selectedIndex > 0) {
                        root.selectedIndex--;
                    }

                    wallpapersList.positionViewAtIndex(root.selectedIndex, ListView.Contain);

                    event.accepted = true;
                }

                Keys.onRightPressed: event => {
                    if (root.applying)
                        return;
                    if (root.wallpapers.length === 0)
                        return;
                    if (root.selectedIndex === -1) {
                        root.selectedIndex = 0;
                    } else if (root.selectedIndex < root.wallpapers.length - 1) {
                        root.selectedIndex++;
                    }

                    wallpapersList.positionViewAtIndex(root.selectedIndex, ListView.Contain);

                    event.accepted = true;
                }

                Keys.onReturnPressed: event => {
                    if (root.applying)
                        return;
                    if (root.selectedIndex >= 0 && root.selectedIndex < root.wallpapers.length) {
                        root.applyWallpaper(root.wallpapers[root.selectedIndex]);
                    }

                    event.accepted = true;
                }

                Keys.onEscapePressed: event => {
                    if (root.applying)
                        return;
                    wallpaperPanel.visible = false;
                    event.accepted = true;
                }

                Component.onCompleted: {
                    forceActiveFocus();
                }

                // ----------------------------------------------------------
                // Main background
                // ----------------------------------------------------------

                Rectangle {
                    anchors.fill: parent

                    color: Theme.background.alpha(0.96)

                    // ------------------------------------------------------
                    // Top title
                    // ------------------------------------------------------

                    RowLayout {
                        id: header

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top

                            leftMargin: 16
                            rightMargin: 16
                            topMargin: 10
                        }

                        height: 24

                        Text {
                            text: root.applying ? "Applying wallpaper" : "Wallpapers"

                            color: root.applying ? Theme.accent : Theme.text

                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true

                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: !root.applying

                            text: "← →   Enter   Esc"

                            color: Theme.textMuted

                            font.family: root.font
                            font.pixelSize: 10

                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    // ------------------------------------------------------
                    // Wallpaper list
                    // ------------------------------------------------------

                    ListView {
                        id: wallpapersList

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: header.bottom
                            bottom: statusBar.top

                            leftMargin: 16
                            rightMargin: 16
                            topMargin: 8
                            bottomMargin: 8
                        }

                        orientation: ListView.Horizontal

                        spacing: 10

                        clip: true

                        model: root.wallpapers

                        currentIndex: root.selectedIndex

                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            id: wallpaperItem

                            width: 180
                            height: 120

                            Rectangle {
                                id: wallpaperCard

                                anchors.fill: parent

                                radius: 10

                                color: index === root.selectedIndex ? Theme.bgSelected : Theme.surface

                                border.width: index === root.selectedIndex ? 2 : 0

                                border.color: Theme.accent

                                opacity: root.applying && index !== root.selectedIndex ? 0.35 : 1

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }

                                // --------------------------------------------------
                                // Thumbnail
                                // --------------------------------------------------

                                Image {
                                    id: thumbnail

                                    anchors.fill: parent

                                    anchors.margins: 4

                                    source: "file://" + root.wallDir + "/" + modelData

                                    fillMode: Image.PreserveAspectCrop

                                    asynchronous: true

                                    cache: true

                                    opacity: root.applying && index === root.selectedIndex ? 0.15 : 1

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                // --------------------------------------------------
                                // Filename
                                // --------------------------------------------------

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

                                    visible: !root.applying

                                    Text {
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter

                                            leftMargin: 8
                                            rightMargin: 8
                                        }

                                        text: modelData

                                        color: Theme.text

                                        font.family: root.font
                                        font.pixelSize: 10

                                        elide: Text.ElideMiddle
                                    }
                                }

                                // --------------------------------------------------
                                // APPLYING overlay
                                // --------------------------------------------------

                                Rectangle {
                                    anchors.fill: parent

                                    radius: parent.radius

                                    visible: root.applying && index === root.selectedIndex

                                    color: Theme.background.alpha(0.88)

                                    Column {
                                        anchors.centerIn: parent

                                        spacing: 7

                                        BusyIndicator {
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            width: 34
                                            height: 34

                                            running: root.applying
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            text: "APPLYING"

                                            color: Theme.accent

                                            font.family: root.font
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            text: "Wallpaper"

                                            color: Theme.textMuted

                                            font.family: root.font
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // --------------------------------------------------
                                // Mouse selection
                                // --------------------------------------------------

                                MouseArea {
                                    anchors.fill: parent

                                    enabled: !root.applying

                                    onClicked: {
                                        root.selectedIndex = index;

                                        Qt.callLater(() => {
                                            keyboardFocus.forceActiveFocus();
                                        });
                                    }

                                    onDoubleClicked: {
                                        root.selectedIndex = index;

                                        root.applyWallpaper(modelData);

                                        Qt.callLater(() => {
                                            keyboardFocus.forceActiveFocus();
                                        });
                                    }
                                }
                            }
                        }

                        // ------------------------------------------------------
                        // Empty state
                        // ------------------------------------------------------

                        Text {
                            anchors.centerIn: parent

                            visible: root.wallpapers.length === 0

                            text: "No wallpapers found"

                            color: Theme.textMuted

                            font.family: root.font
                            font.pixelSize: 12
                        }
                    }

                    // ------------------------------------------------------
                    // Status bar
                    // ------------------------------------------------------

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
                                visible: root.applying

                                width: 18
                                height: 18

                                running: root.applying
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter

                                text: root.applying ? "APPLYING WALLPAPER..." : root.selectedIndex >= 0 ? root.wallpapers[root.selectedIndex] : "Select a wallpaper"

                                color: root.applying ? Theme.accent : root.selectedIndex >= 0 ? Theme.text : Theme.textMuted

                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: root.applying
                            }
                        }
                    }

                    // ------------------------------------------------------
                    // Applying blocker
                    // ------------------------------------------------------

                    Rectangle {
                        anchors.fill: parent

                        visible: root.applying

                        color: "transparent"

                        z: 100

                        MouseArea {
                            anchors.fill: parent

                            enabled: root.applying

                            onClicked: {}
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                Qt.callLater(() => {
                    keyboardFocus.forceActiveFocus();
                });
            }
        }
    }
}
