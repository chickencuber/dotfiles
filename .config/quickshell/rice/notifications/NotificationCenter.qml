import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import ".."

PanelWindow {
    id: root

    required property var notificationServer

    visible: false
    focusable: true

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    property int marginTop: 0

    anchors {
        top: true
        right: true
        left: true
        bottom: true
    }

    property bool dndEnabled: false

    // ============================================================
    // MPRIS
    // ============================================================

    property var selectedPlayer: null

    readonly property var mediaPlayer: {
        const players = Mpris.players.values;

        if (root.selectedPlayer !== null) {
            for (let i = 0; i < players.length; ++i) {
                if (players[i] === root.selectedPlayer)
                    return root.selectedPlayer;
            }

            root.selectedPlayer = null;
        }

        for (let i = 0; i < players.length; ++i) {
            const player = players[i];

            const identity = (player.identity || "").toLowerCase();

            const desktopEntry = (player.desktopEntry || "").toLowerCase();

            const dbusName = (player.dbusName || "").toLowerCase();

            if (identity === "rice" || desktopEntry === "rice" || dbusName.includes("rice")) {
                return player;
            }
        }

        if (players.length > 0)
            return players[0];

        return null;
    }

    function playerIndex(player) {
        const players = Mpris.players.values;

        for (let i = 0; i < players.length; ++i) {
            if (players[i] === player)
                return i;
        }

        return -1;
    }

    function nextPlayer() {
        const players = Mpris.players.values;

        if (players.length < 2)
            return;

        let index = playerIndex(root.mediaPlayer);

        if (index < 0)
            index = 0;

        root.selectedPlayer = players[(index + 1) % players.length];
    }

    function previousPlayer() {
        const players = Mpris.players.values;

        if (players.length < 2)
            return;

        let index = playerIndex(root.mediaPlayer);

        if (index < 0)
            index = 0;

        root.selectedPlayer = players[(index - 1 + players.length) % players.length];
    }

    // ============================================================
    // IPC
    // ============================================================

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            root.visible ? root.close() : root.open();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    function open(): void {
        root.visible = true;

        Qt.callLater(() => {
            panel.forceActiveFocus();
        });
    }

    function close(): void {
        root.visible = false;
    }

    function clearNotifications(): void {
        const notifications = root.notificationServer.trackedNotifications.values.slice();

        for (const notification of notifications)
            notification.dismiss();
    }

    // ============================================================
    // CLICK OUTSIDE
    // ============================================================

    MouseArea {
        anchors.fill: parent
        z: 0

        onClicked: root.close()
    }

    // ============================================================
    // CONTROL CENTER
    // ============================================================

    Rectangle {
        id: panel
        anchors.rightMargin: 8
        anchors.topMargin: 8 + root.marginTop

        z: 1

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        width: 500

        // SwayNC control-center is transparent.
        color: "transparent"

        border.width: 0

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }

        // ========================================================
        // CONTENT
        // ========================================================

        ColumnLayout {
            anchors.fill: parent

            anchors.margins: 16

            spacing: 12

            // ====================================================
            // HEADER
            // ====================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                radius: 18

                color: Qt.alpha(Theme.background, 0.85)

                border.width: 1
                border.color: Theme.accent

                RowLayout {
                    anchors.fill: parent

                    anchors.leftMargin: 16
                    anchors.rightMargin: 10

                    spacing: 8

                    Text {
                        Layout.fillWidth: true

                        text: "Notifications"

                        color: Theme.text

                        font.family: "JetBrainsMono Nerd Font Mono"

                        font.pixelSize: 18
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 30

                        radius: 10

                        color: clearMouse.containsMouse ? Qt.alpha(Theme.accent, 0.16) : Qt.alpha(Theme.text, 0.07)

                        border.width: 1

                        border.color: clearMouse.containsMouse ? Theme.accent : Qt.alpha(Theme.text, 0.12)

                        Text {
                            anchors.centerIn: parent

                            text: "Clear"

                            color: Theme.text

                            font.family: "JetBrainsMono Nerd Font Mono"

                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: clearMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.clearNotifications()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30

                        radius: 10

                        color: closeMouse.containsMouse ? Qt.alpha(Theme.text, 0.12) : Qt.alpha(Theme.text, 0.07)

                        border.width: 1

                        border.color: closeMouse.containsMouse ? Theme.accent : Qt.alpha(Theme.text, 0.12)

                        Text {
                            anchors.centerIn: parent

                            text: "󰅖"

                            color: Theme.text

                            font.family: "JetBrainsMono Nerd Font Mono"

                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.close()
                        }
                    }
                }
            }

            // ====================================================
            // DND WIDGET
            // ====================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                radius: 22

                color: Qt.alpha(Theme.background, 0.85)

                border.width: 1
                border.color: Theme.accent

                RowLayout {
                    anchors.fill: parent

                    anchors.leftMargin: 16
                    anchors.rightMargin: 14

                    spacing: 10

                    Text {
                        Layout.fillWidth: true

                        text: "Do Not Disturb"

                        color: Theme.text

                        font.family: "JetBrainsMono Nerd Font Mono"

                        font.pixelSize: 13
                    }

                    Rectangle {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 26

                        radius: 13

                        color: root.dndEnabled ? Theme.accent : Qt.alpha(Theme.text, 0.18)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Rectangle {
                            width: 20
                            height: 20

                            radius: 10

                            anchors.verticalCenter: parent.verticalCenter

                            x: root.dndEnabled ? parent.width - width - 3 : 3

                            color: root.dndEnabled ? Theme.surface : Theme.text

                            Behavior on x {
                                NumberAnimation {
                                    duration: 150

                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.dndEnabled = !root.dndEnabled
                        }
                    }
                }
            }

            // ====================================================
            // MPRIS WIDGET
            // ====================================================

            Rectangle {
                Layout.fillWidth: true

                // Explicit, predictable height.
                implicitHeight: mprisColumn.implicitHeight + 28

                radius: 22

                color: Qt.alpha(Theme.background, 0.90)

                border.width: 1
                border.color: Theme.accent

                ColumnLayout {
                    id: mprisColumn

                    anchors.fill: parent
                    anchors.margins: 14

                    spacing: 10

                    // ============================================================
                    // PLAYER SWITCHER
                    // ============================================================

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        Layout.alignment: Qt.AlignHCenter

                        spacing: 4

                        Repeater {
                            model: Mpris.players.values

                            delegate: Rectangle {
                                required property var modelData

                                Layout.preferredWidth: modelData === root.mediaPlayer ? 24 : 6

                                Layout.preferredHeight: 6

                                radius: 999

                                color: modelData === root.mediaPlayer ? Theme.accent : Qt.alpha(Theme.text, 0.30)

                                Behavior on Layout.preferredWidth {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root.selectedPlayer = modelData;
                                    }
                                }
                            }
                        }
                    }

                    // ============================================================
                    // PLAYER NAME
                    // ============================================================

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 28

                            radius: 9

                            color: previousPlayerMouse.containsMouse ? Qt.alpha(Theme.accent, 0.16) : Qt.alpha(Theme.text, 0.06)

                            border.width: previousPlayerMouse.containsMouse ? 1 : 0

                            border.color: Theme.accent

                            Text {
                                anchors.centerIn: parent

                                text: "󰁍"

                                color: Theme.text

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 15
                            }

                            MouseArea {
                                id: previousPlayerMouse

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: root.previousPlayer()
                            }
                        }

                        Text {
                            Layout.fillWidth: true

                            text: root.mediaPlayer ? (root.mediaPlayer.identity || root.mediaPlayer.desktopEntry || "Media") : "No media player"

                            color: Theme.text
                            opacity: 0.75

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 11
                            font.bold: true

                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 28

                            radius: 9

                            color: nextPlayerMouse.containsMouse ? Qt.alpha(Theme.accent, 0.16) : Qt.alpha(Theme.text, 0.06)

                            border.width: nextPlayerMouse.containsMouse ? 1 : 0

                            border.color: Theme.accent

                            Text {
                                anchors.centerIn: parent

                                text: "󰁔"

                                color: Theme.text

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 15
                            }

                            MouseArea {
                                id: nextPlayerMouse

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: root.nextPlayer()
                            }
                        }
                    }

                    // ============================================================
                    // ART + TRACK INFO
                    // ============================================================

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 88

                        spacing: 14

                        // --------------------------------------------------------
                        // ART
                        // --------------------------------------------------------

                        Rectangle {
                            Layout.preferredWidth: 88
                            Layout.preferredHeight: 88

                            radius: 16

                            color: Qt.alpha(Theme.text, 0.07)

                            clip: true

                            Image {
                                id: trackArt

                                anchors.fill: parent

                                source: root.mediaPlayer ? root.mediaPlayer.trackArtUrl : ""

                                fillMode: Image.PreserveAspectCrop

                                asynchronous: true
                                smooth: true

                                sourceSize.width: 176
                                sourceSize.height: 176

                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent

                                text: "󰝚"

                                color: Theme.accent

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 30

                                visible: !trackArt.visible
                            }
                        }

                        // --------------------------------------------------------
                        // INFO
                        // --------------------------------------------------------

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            spacing: 4

                            Text {
                                Layout.fillWidth: true

                                text: root.mediaPlayer ? (root.mediaPlayer.trackTitle || "Unknown Title") : "Nothing playing"

                                color: Theme.text

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 14
                                font.bold: true

                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true

                                text: root.mediaPlayer ? (root.mediaPlayer.trackArtist || "Unknown Artist") : "No media player"

                                color: Theme.text
                                opacity: 0.55

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 11

                                elide: Text.ElideRight
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // ============================================================
                    // PLAYBACK CONTROLS
                    // ============================================================

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignHCenter

                        spacing: 8

                        // --------------------------------------------------------
                        // PREVIOUS TRACK
                        // --------------------------------------------------------

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 32

                            radius: 10

                            color: previousMouse.containsMouse ? Qt.alpha(Theme.accent, 0.15) : Qt.alpha(Theme.text, 0.06)

                            Text {
                                anchors.centerIn: parent

                                text: "󰒮"

                                color: Theme.text

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 17
                            }

                            MouseArea {
                                id: previousMouse

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (root.mediaPlayer && root.mediaPlayer.canGoPrevious) {
                                        root.mediaPlayer.previous();
                                    }
                                }
                            }
                        }

                        // --------------------------------------------------------
                        // PLAY / PAUSE
                        // --------------------------------------------------------

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 36

                            radius: 11

                            color: playMouse.containsMouse ? Qt.alpha(Theme.accent, 0.20) : Qt.alpha(Theme.text, 0.08)

                            border.width: playMouse.containsMouse ? 1 : 0

                            border.color: Theme.accent

                            Text {
                                anchors.centerIn: parent

                                text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰏤" : "󰐊"

                                color: Theme.text

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 19
                            }

                            MouseArea {
                                id: playMouse

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (root.mediaPlayer && root.mediaPlayer.canTogglePlaying) {
                                        root.mediaPlayer.togglePlaying();
                                    }
                                }
                            }
                        }

                        // --------------------------------------------------------
                        // NEXT TRACK
                        // --------------------------------------------------------

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 32

                            radius: 10

                            color: nextMouse.containsMouse ? Qt.alpha(Theme.accent, 0.15) : Qt.alpha(Theme.text, 0.06)

                            Text {
                                anchors.centerIn: parent

                                text: "󰒭"

                                color: Theme.text

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 17
                            }

                            MouseArea {
                                id: nextMouse

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (root.mediaPlayer && root.mediaPlayer.canGoNext) {
                                        root.mediaPlayer.next();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                radius: 18
                color: Qt.alpha(Theme.background, 0.85)
                border.width: 1
                border.color: Theme.accent

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        Layout.fillWidth: true

                        text: "Recent Notifications"

                        color: Theme.text

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        contentWidth: width
                        contentHeight: notificationColumn.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: notificationColumn

                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: root.notificationServer.trackedNotifications

                                delegate: NotificationPopupItem {
                                    required property var modelData

                                    notification: modelData
                                    popupMode: false

                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 20

                                visible: root.notificationServer.trackedNotifications.length === 0

                                text: "No notifications"

                                horizontalAlignment: Text.AlignHCenter

                                color: Theme.text
                                opacity: 0.45

                                font.family: "JetBrainsMono Nerd Font Mono"
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }
}
