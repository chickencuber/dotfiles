import QtQuick
import QtQuick.Controls
import "../singletons/"

Module {
    id: mod

    property alias text: button.text
    property alias font: button.font
    property alias color: button.palette.buttonText
    property alias background: button.background
    property alias contentItem: button.contentItem
    signal clicked()

    Button {
        id: button
        padding: 7

        width: implicitWidth
        height: mod.bar_thickness

        font.family: Theme.font
        font.pointSize: 12

        palette.buttonText: Theme.text

        background: Rectangle {
            color: Theme.background
            border.width: 1
            border.color: Theme.accent
            radius: 10
        }

        onClicked: mod.clicked()
    }
}

