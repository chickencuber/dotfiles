import QtQuick
import QtQuick.Effects
import Quickshell
import "../singletons"

Item {
    width: 100
    height: 100

    Image {
        id: profileImage
        anchors.fill: parent

        source: "file:///var/lib/AccountsService/icons/" + Quickshell.env("USER")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    Rectangle {
        id: profileMask
        anchors.fill: parent
        radius: width / 2
        color: "white"
        visible: false
    }

    ShaderEffectSource {
        id: profileMaskSource
        sourceItem: profileMask
        hideSource: true
    }

    MultiEffect {
        anchors.fill: parent
        source: profileImage

        maskEnabled: true
        maskSource: profileMaskSource
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
    }
}
