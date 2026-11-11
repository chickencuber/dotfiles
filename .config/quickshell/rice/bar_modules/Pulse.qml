import QtQuick
import Quickshell.Services.Pipewire
import "../singletons/"
import "../components/"

BarButton {
    id: root

    property int spacing: 7
    property int iconSize: 16

    property color textColor: Theme.text

    property bool showOutputVolume: true
    property bool showOutputIcon: true
    property bool showSourceVolume: true
    property bool showSourceIcon: true

    property string outputMutedText: ""
    property string sourceMutedText: ""


    readonly property var sink: Pipewire.defaultAudioSink

    readonly property var source: {
        const defaultSource = Pipewire.defaultAudioSource

        if (defaultSource?.audio)
            return defaultSource

        for (const node of Pipewire.nodes.values) {
            if (!node.isSink && node.audio)
                return node
        }

        return null
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property int volume:
        root.sink?.audio ? Math.round(root.sink.audio.volume * 100) : 0

    readonly property bool muted:
        root.sink?.audio ? root.sink.audio.muted : false

    readonly property int sourceVolume:
        root.source?.audio ? Math.round(root.source.audio.volume * 100) : 0

    readonly property bool sourceMuted:
        root.source?.audio ? root.source.audio.muted : false

    readonly property string outputIcon: {
        if (root.muted)
            return "audio-volume-muted-symbolic"

        if (root.volume <= 33)
            return "audio-volume-low-symbolic"

        if (root.volume <= 66)
            return "audio-volume-medium-symbolic"

        return "audio-volume-high-symbolic"
    }

    readonly property string sourceIcon:
        root.sourceMuted
            ? "microphone-sensitivity-muted-symbolic"
            : "audio-input-microphone-symbolic"

    contentItem: Row {
        id: row

        anchors.fill: parent
        anchors.margins: 8
        spacing: root.spacing

        Text {
            id: outputText

            visible: root.showOutputVolume
            anchors.verticalCenter: parent.verticalCenter

            width: 40
            horizontalAlignment: Text.AlignHCenter

            text: root.muted ? root.outputMutedText : `${root.volume}%`

            font.family: Theme.font
            color: root.textColor
        }

        Icon {
            visible: root.showOutputIcon
            anchors.verticalCenter: parent.verticalCenter

            width: root.iconSize
            height: width

            source: Icon.System
            name: root.outputIcon
            monochrome: true
            iconColor: root.textColor
        }

        Text {
            id: sourceText

            visible: root.showSourceVolume
            anchors.verticalCenter: parent.verticalCenter

            width: 40
            horizontalAlignment: Text.AlignHCenter

            text: root.sourceMuted
                ? root.sourceMutedText
                : `${root.sourceVolume}%`

            font.family: Theme.font
            color: root.textColor
        }

        Icon {
            visible: root.showSourceIcon
            anchors.verticalCenter: parent.verticalCenter

            width: root.iconSize
            height: width

            source: Icon.System
            name: root.sourceIcon
            monochrome: true
            iconColor: root.textColor
        }
    }
}
