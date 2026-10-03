import QtQuick
import Quickshell
import ".."

PopupWindow {
    id: root

    property string text: ""

    property Item target: null
    property real mouseX: 0
    property real mouseY: 0

    property int delay: 400
    property int offset: 12
    property int padding: 8

    visible: false
    color: "transparent"

    implicitWidth: tooltipText.implicitWidth + root.padding * 2
    implicitHeight: tooltipText.implicitHeight + root.padding * 2

    // Completely click-through.
    mask: Region {}

    // The anchor is the mouse position inside the target.
    anchor.item: root.target

    anchor.rect.x: root.mouseX
    anchor.rect.y: root.mouseY
    anchor.rect.width: 1
    anchor.rect.height: 1

    // Prefer below the mouse.
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Top

    anchor.margins.top: root.offset

    Rectangle {
        anchors.fill: parent

        color: Theme.background
        radius: 8

        border.width: 1
        border.color: Theme.accent

        Text {
            id: tooltipText

            anchors.centerIn: parent

            text: root.text

            color: Theme.text
            font.family: "Hack Nerd Font"
            font.pixelSize: 12
        }
    }

    Timer {
        id: showTimer

        interval: root.delay
        repeat: false

        onTriggered: {
            if (root.target && root.text !== "")
                root.visible = true
        }
    }

    function show(item: Item, value: string, x: real, y: real): void {
        showTimer.stop()

        root.visible = false
        root.target = item
        root.text = value
        root.mouseX = x
        root.mouseY = y

        showTimer.start()
    }

    function move(x: real, y: real): void {
        root.mouseX = x
        root.mouseY = y
    }

    function hide(): void {
        showTimer.stop()

        root.visible = false
        root.target = null
        root.text = ""
    }
}
