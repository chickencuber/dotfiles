import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import ".."

Rectangle {
    id: root
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            expireTimer.stop();
        }

        onExited: {
            expireTimer.restart();
        }
    }

    required property var notification

    implicitWidth: popupMode ? 500 : 450
    implicitHeight: content.implicitHeight + 24

    property bool popupMode: true

    radius: 14
    color: Qt.alpha(Theme.background, 0.95)

    border.width: 1
    border.color: Theme.accent

    function sendReply() {
        if (!root.notification?.hasInlineReply)
            return;
        const text = replyField.text.trim();

        if (text === "")
            return;
        root.notification.sendInlineReply(text);
        replyField.clear();
    }

    property bool popupVisible: true
    visible: root.popupMode ? root.popupVisible : true
    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Notification image
            Item {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80

                visible: notificationImage.status === Image.Ready
                clip: true

                Image {
                    id: notificationImage

                    anchors.fill: parent
                    source: root.notification?.image ?? ""

                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true

                    sourceSize.width: 160
                    sourceSize.height: 160
                }
            }

            // App icon
            IconImage {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                source: {
                    const icon = root.notification?.appIcon ?? "";

                    if (icon === "")
                        return "";

                    if (icon.startsWith("/") || icon.startsWith("file://"))
                        return icon;

                    return Quickshell.iconPath(icon, true);
                }
            }

            // Notification content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                spacing: 2

                Text {
                    Layout.fillWidth: true

                    text: (root.notification?.appName ?? "").replace(/<br\s*\/?>/gi, "  \n")
                    textFormat: Text.MarkdownText

                    color: Theme.text
                    opacity: 0.55

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 11

                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true

                    text: (root.notification?.summary ?? "").replace(/<br\s*\/?>/gi, "  \n")

                    color: Theme.text

                    textFormat: Text.MarkdownText

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 15
                    font.bold: true

                    wrapMode: Text.Wrap
                }

                Text {
                    Layout.fillWidth: true

                    visible: text !== ""

                    text: (root.notification?.body ?? "").replace(/<br\s*\/?>/gi, "  \n")

                    textFormat: Text.MarkdownText

                    color: Theme.text
                    opacity: 0.8

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13

                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                }
            }

            // Close button
            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28

                radius: 8

                color: closeMouse.containsMouse ? Qt.alpha(Theme.text, 0.15) : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: "󰅖"

                    color: Theme.text

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.notification?.dismiss();
                    }
                }
            }
        }

        // Inline reply
        RowLayout {
            Layout.fillWidth: true

            visible: root.notification?.hasInlineReply ?? false

            spacing: 6

            TextField {
                id: replyField

                Layout.fillWidth: true
                Layout.preferredHeight: 34

                placeholderText: root.notification?.inlineReplyPlaceholder || "Type a reply..."

                color: Theme.text
                placeholderTextColor: Qt.alpha(Theme.text, 0.45)

                font.family: "JetBrainsMono Nerd Font Mono"
                font.pixelSize: 12

                background: Rectangle {
                    radius: 8

                    color: Qt.alpha(Theme.text, 0.07)

                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.12)
                }

                Keys.onReturnPressed: {
                    root.sendReply();
                }
            }

            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 34

                radius: 8

                color: sendMouse.containsMouse ? Qt.alpha(Theme.text, 0.15) : Qt.alpha(Theme.text, 0.07)

                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.12)

                Text {
                    anchors.centerIn: parent

                    text: "Send"

                    color: Theme.text

                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: sendMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.sendReply();
                    }
                }
            }
        }

        // Notification actions
        RowLayout {
            Layout.fillWidth: true

            visible: (root.notification?.actions?.length ?? 0) > 0

            spacing: 6

            Repeater {
                model: root.notification?.actions ?? []

                delegate: Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    radius: 8

                    color: actionMouse.containsMouse ? Qt.alpha(Theme.text, 0.15) : Qt.alpha(Theme.text, 0.07)

                    border.width: 1
                    border.color: Qt.alpha(Theme.text, 0.12)

                    RowLayout {
                        anchors.centerIn: parent

                        spacing: 6

                        // Action icon
                        IconImage {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16

                            visible: root.notification?.hasActionIcons ?? false

                            source: {
                                if (!root.notification?.hasActionIcons)
                                    return "";

                                const icon = modelData.identifier ?? "";

                                if (icon === "")
                                    return "";

                                return Quickshell.iconPath(icon, true);
                            }
                        }

                        Text {
                            text: modelData.text

                            color: Theme.text

                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 12

                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            modelData.invoke();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: expireTimer

        interval: {
            const timeout = root.notification?.expireTimeout ?? 0;

            return timeout > 0 ? timeout * 1000 : 5000;
        }

        running: true
        repeat: false

        onTriggered: {
            root.popupVisible = false;
        }
    }
}
