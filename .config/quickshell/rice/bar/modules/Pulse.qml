import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../.."

Item {
    id: root

    // ───── Configuration ─────

    property string font: "JetBrainsMono Nerd Font Mono"
    property int size: 40
    property int spacing: 8
    property int iconSize: 8

    property color textColor: Theme.text

    property bool showOutputVolume: true
    property bool showOutputIcon: true
    property bool showSourceVolume: true
    property bool showSourceIcon: true

    property string outputMutedText: ""
    property string sourceMutedText: ""
    property string command: "pavucontrol"

    // ───── PipeWire ─────

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property var source: {
        const defaultSource = Pipewire.defaultAudioSource;

        if (defaultSource?.audio)
            return defaultSource;

        for (const node of Pipewire.nodes.values) {
            if (!node.isSink && node.audio) {
                return node;
            }
        }

        return null;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // ───── Audio state ─────

    readonly property int volume: root.sink?.audio ? Math.round(root.sink.audio.volume * 100) : 0

    readonly property bool muted: root.sink?.audio ? root.sink.audio.muted : false

    readonly property int sourceVolume: root.source?.audio ? Math.round(root.source.audio.volume * 100) : 0

    readonly property bool sourceMuted: root.source?.audio ? root.source.audio.muted : false

    // ───── Icons ─────

    readonly property string outputIcon: {
        if (root.muted)
            return "";

        if (root.volume <= 33)
            return "";

        if (root.volume <= 66)
            return "";

        return "";
    }

    readonly property string sourceIcon: root.sourceMuted ? "" : ""

    // ───── Layout ─────

    implicitWidth: row.implicitWidth
    height: root.size

    property Component background: Component {
        Rectangle {
            color: Theme.background
            radius: 10
            border.color: Theme.accent
            border.width: 1
        }
    }
    Loader {
        anchors.fill: parent
        sourceComponent: root.background
    }

    Row {
        id: row
        padding: 8
        anchors.fill: parent

        spacing: root.spacing

        Text {
            id: text
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showOutputVolume
            text: root.muted ? root.outputMutedText : `${root.volume}%`

            font.family: root.font
            color: root.textColor
        }

        Text {
            visible: root.showOutputIcon
            anchors.verticalCenter: parent.verticalCenter

            text: root.outputIcon

            font.family: root.font
            font.pixelSize: text.font.pixelSize + root.iconSize
            color: root.textColor
        }

        Text {
            visible: root.showSourceVolume
            anchors.verticalCenter: parent.verticalCenter

            text: root.sourceMuted ? root.sourceMutedText : `${root.sourceVolume}%`

            font.family: root.font
            color: root.textColor
        }

        Text {
            visible: root.showSourceIcon
            anchors.verticalCenter: parent.verticalCenter

            text: root.sourceIcon

            font.family: root.font
            font.pixelSize: text.font.pixelSize + root.iconSize
            color: root.textColor
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            Quickshell.execDetached([root.command])
        }
    }
}
