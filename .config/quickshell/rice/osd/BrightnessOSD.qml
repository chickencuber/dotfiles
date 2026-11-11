pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property real brightness: 0

    readonly property string backlightIcon: {
        const value = brightness * 100;
        if (value <= 10)
            return "brightness_1";
        if (value <= 20)
            return "brightness_2";
        if (value <= 30)
            return "brightness_3";
        if (value <= 40)
            return "brightness_4";
        if (value <= 50)
            return "brightness_5";
        if (value <= 60)
            return "brightness_6";

        return "brightness_7";
    }

    Process {
        id: updateBrightness

        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");

                if (parts.length < 4)
                    return;

                const value = parseInt(parts[3].replace("%", ""));

                if (!isNaN(value))
                    root.brightness = value / 100;
            }
        }
    }

    OSD {
        ipc: "osd.brightness"

        icon: root.backlightIcon
        value: root.brightness
        onTriggered: updateBrightness.running = true

        Component.onCompleted: updateBrightness.running = true
    }
}
