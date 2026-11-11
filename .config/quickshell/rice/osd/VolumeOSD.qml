pragma Singleton
import "../components/"
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string volumeIcon: {
        if (muted || volume <= 0)
        return "audio-volume-muted-symbolic";
        if (volume <= 0.33)
        return "audio-volume-low-symbolic";
        if (volume <= 0.66)
        return "audio-volume-medium-symbolic";

        return "audio-volume-high-symbolic";
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    OSD {
        ipc: "osd.volume"

        icon: root.volumeIcon
        source: Icon.System
        value: root.muted ? 0 : root.volume

        onTriggered: {}
    }
}
