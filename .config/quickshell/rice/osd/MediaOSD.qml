pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../components/"

Scope {
    id: root

    property string title: "Nothing Playing"
    property string artist: ""
    property string artwork: ""
    property bool playing: false

    Process {
        id: getMedia

        command: ["playerctl", "metadata", "--format", "{{title}}|{{artist}}|{{status}}|{{mpris:artUrl}}"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");

                if (parts.length >= 3) {
                    root.title = parts[0] || "Unknown Title";
                    root.artist = parts[1] || "Unknown Artist";
                    root.playing = parts[2] === "Playing";
                    root.artwork = parts[3] || "";
                } else {
                    root.reset();
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.reset();
        }
    }

    OSD {
        ipc: "osd.media"

        icon: root.playing ? "media-playback-start-symbolic" : root.title === "Nothing Playing" ? "audio-x-generic-symbolic" : "media-playback-pause-symbolic"
        source: Icon.System

        label: root.title
        subtitle: root.artist
        image: root.artwork

        showProgress: false
        showValue: false

        imageSize: 44
        timeout: 1500

        onTriggered: getMedia.running = true
    }

    function reset(): void {
        title = "Nothing Playing";
        artist = "";
        artwork = "";
        playing = false;
    }
}
