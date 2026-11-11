import QtQuick
import Quickshell
import Qt5Compat.GraphicalEffects
import "../singletons"

Item {
    id: root

    enum Source {
        Font,
        System
    }

    property string name: ""
    property int source: Icon.Font
    property string font: Theme.iconFont
    property bool monochrome: false
    property color iconColor: Theme.text
    property bool filled: false

    Text {
        renderType: Text.NativeRendering
        anchors.fill: parent
        visible: root.source === Icon.Font
        anchors.margins: -2

        text: root.name
        font.family: root.font
        font.pixelSize: Math.min(root.width, root.height)
        font.variableAxes: {
            "FILL": root.filled ? 1 : 0,
        }

        color: root.iconColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Image {
        id: image
        anchors.fill: parent
        visible: root.source === Icon.System

        source: Quickshell.iconPath(root.name, true)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        anchors.verticalCenter: parent.verticalCenter
    }
    ColorOverlay {
        visible: root.monochrome && root.source == Icon.System
        anchors.fill: image
        source: image
        color: root.iconColor
    }
}
