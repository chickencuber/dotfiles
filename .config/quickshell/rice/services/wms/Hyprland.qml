pragma Singleton

import Quickshell.Io
import QtQuick
import Quickshell.Hyprland as QHyprland

WM {
    id: root

    focusedWindow: QHyprland.Hyprland.activeToplevel
    focusedWorkspace: QHyprland.Hyprland.focusedWorkspace
    workspaces: QHyprland.Hyprland.workspaces
    name: "Hyprland"

    property var done
    property var doneKeys

    function switchWorkspace(id) {
        QHyprland.Hyprland.dispatch("workspace " + id);
    }

    function updateCursorPosition(callback = () => {}) {
        cursorProcess.running = true;
        done = callback;
    }

    function updateKeys(callback = () => {}) {
        keysDelay.running = true;
        doneKeys = callback;
    }

    Process {
        id: cursorProcess
        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            id: cursorOutput

            onStreamFinished: {
                const parts = cursorOutput.text.trim().split(",");

                if (parts.length !== 2)
                    return;
                const x = Number(parts[0]);
                const y = Number(parts[1]);

                if (!Number.isFinite(x) || !Number.isFinite(y))
                    return;
                root.cursorPosition = Qt.point(x, y);
                root.done();
            }
        }
    }
    Process {
        id: keysProcess

        command: ["hyprctl", "devices", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);

                    if (!data.keyboards)
                        return;

                    const keyboard = data.keyboards.find(k => k.main);

                    if (!keyboard)
                        return;

                    root.caps = keyboard.capsLock;

                    root.num = keyboard.numLock;
                } catch (error) {
                    console.warn("Failed to update keyboard state:", error);
                }

                if (root.doneKeys) {
                    root.doneKeys();
                    root.doneKeys = null;
                }
            }
        }
    }

    Timer {
        id: keysDelay
        interval: 75
        repeat: false

        onTriggered: keysProcess.running = true
    }

    Process {
        id: screenshotProcess

        property var pendingCommand: []

        command: pendingCommand
    }

    function screenshot(mode: int, directory: string): void {
        if (screenshotProcess.running)
            return;
        let args = ["hyprshot"];

        switch (mode) {
        case WM.ActiveMonitor:
            args.push("-m", "active", "--mode", "output");
            break;
        case WM.ActiveWindow:
            args.push("-m", "active", "--mode", "window");
            break;
        case WM.Monitor:
            args.push("-m", "output");
            break;
        case WM.Window:
            args.push("-m", "window");
            break;
        case WM.Region:
            args.push("-m", "region");
            break;
        default:
            return;
        }

        args.push("-o", directory);

        screenshotProcess.pendingCommand = args;
        screenshotProcess.running = true;
    }
}
