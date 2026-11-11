import QtQuick
import QtQuick.Controls
import "../singletons"

Button {
    id: root

    property string name: ""
    property int source: Icon.Font
    property string iconFont: Theme.iconFont
    property alias iconColor: icon.iconColor
    property alias monochrome: icon.monochrome
    property alias filled: icon.filled

    contentItem: Icon {
        id: icon

        anchors.fill: parent

        name: root.name
        source: root.source
        font: root.iconFont
        anchors.margins: 6
    }

    background: Rectangle {
        color: root.down ? Theme.accent : Theme.background
        border.width: 1
        border.color: Theme.accent
        radius: 10
    }
}
