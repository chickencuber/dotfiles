import QtQuick
import QtQuick.Layouts
import Quickshell
import "../singletons/"
import "../components/"

Scope {
    id: root

    property string icon: ""
    property string label: ""
    property string subtitle: ""
    property url image: ""
    property string ipc: ""
    property real value: 0
    property int source: Icon.Font

    property bool showProgress: true
    property bool showValue: true

    property int imageSize: 44
    property int timeout: 1000

    readonly property real normalizedValue: Math.max(0, Math.min(1, value))

    signal triggered
    function open() {
        panel.open = true;
        hideTimer.restart();
    }
    function afterTriggered() {
        open();
    }

    Timer {
        id: hideTimer

        interval: root.timeout

        onTriggered: panel.open = false
    }

    FloatingPanel {
        id: panel

        ipc: root.ipc

        onAnimationFinished: {
            if (open)
                hideTimer.restart();
            else
                hideTimer.stop();
        }

        onRan: {
            root.triggered();
            root.afterTriggered();
        }

        width: Math.min(content.implicitWidth + 32, 400)
        height: Math.max(60, root.image !== "" ? root.imageSize + 16 : 60)

        origin: FloatingPanel.Center

        background: "transparent"
        anchors.bottom: true
        marginBottom: 50

        Rectangle {
            anchors.fill: parent

            radius: height / 2

            color: Qt.alpha(Theme.background, 0.8)

            border.width: 1
            border.color: Theme.accent

            RowLayout {
                id: content
                anchors.fill: parent

                anchors.leftMargin: 16
                anchors.rightMargin: 16

                spacing: 12

                Image {
                    visible: root.image.toString() !== ""

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.imageSize
                    Layout.preferredHeight: root.imageSize

                    source: root.image
                    sourceSize: Qt.size(root.imageSize, root.imageSize)

                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(Theme.text, 0.15)
                    }
                }

                Icon {
                    visible: root.icon !== ""

                    Layout.alignment: Qt.AlignVCenter

                    source: root.source
                    name: root.icon

                    implicitWidth: 20
                    implicitHeight: 20

                    monochrome: true
                }

                ColumnLayout {
                    visible: root.label !== "" || root.subtitle !== ""

                    Layout.fillWidth: !root.showProgress
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter

                    spacing: 0

                    Text {
                        visible: root.label !== ""

                        Layout.fillWidth: true

                        text: root.label

                        font.family: Theme.font
                        font.pixelSize: root.subtitle !== "" ? 15 : 16
                        font.bold: root.subtitle !== ""

                        color: Theme.text

                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.subtitle !== ""

                        Layout.fillWidth: true

                        text: root.subtitle

                        font.family: Theme.font
                        font.pixelSize: 12

                        color: Qt.alpha(Theme.text, 0.6)

                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    visible: root.showProgress

                    Layout.fillWidth: true
                    Layout.minimumWidth: 150
                    Layout.alignment: Qt.AlignVCenter

                    implicitHeight: 6

                    radius: 999

                    color: Qt.alpha(Theme.text, 0.5)

                    Rectangle {
                        width: parent.width * root.normalizedValue

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        radius: 999

                        color: Theme.text
                    }
                }

                Text {
                    visible: root.showValue

                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 40


                    horizontalAlignment: Text.AlignRight

                    text: `${Math.round(root.normalizedValue * 100)}%`

                    font.family: Theme.font
                    font.pixelSize: 16

                    color: Theme.text
                }
            }
        }
    }
}
