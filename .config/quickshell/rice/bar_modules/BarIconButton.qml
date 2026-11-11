import QtQuick
import "../singletons/"
import "../components/"

Module {
    id: mod

    property alias name: button.name
    property alias source: button.source
    property alias iconFont: button.iconFont
    property alias background: button.background
    property alias monochrome: button.monochrome
    property alias iconColor: button.iconColor
    property alias filled: button.filled
    property alias contentItem: button.contentItem
    signal clicked

    IconButton {
        id: button

        width: mod.bar_thickness
        height: mod.bar_thickness

        background: Rectangle {
            color: Theme.background
            border.width: 1
            border.color: Theme.accent
            radius: 10
        }

        onClicked: mod.clicked()
    }
}
