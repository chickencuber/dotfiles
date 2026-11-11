pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property string wallDir:
        Quickshell.env("HOME") + "/.config/quickshell/walls"

    readonly property string statePath:
        Quickshell.env("HOME") + "/.local/state/quickshell/rice/wallpaper"

    property list<string> wallpapers: []
    property string currentWallpaper: ""

    FileView {
        id: wallpaperFile

        path: root.statePath
        watchChanges: true

        onLoadedChanged: {
            if (!loaded)
                return

            root.currentWallpaper = text().trim()
        }
    }

    function refresh(callback = () => {}): void {
        if (findWallpapers.running)
            return

        findWallpapers.callback = callback
        findWallpapers.running = true
    }

    Process {
        id: findWallpapers

        property var callback: null

        command: [
            "find",
            root.wallDir,
            "-maxdepth", "1",
            "-type", "f",
            "(",
            "-iname", "*.png",
            "-o",
            "-iname", "*.gif",
            ")",
            "-printf", "%f\n"
        ]

        stdout: StdioCollector {
            id: wallpaperOutput

            onStreamFinished: {
                const output = wallpaperOutput.text.trim()

                root.wallpapers = output === ""
                    ? []
                    : output
                        .split("\n")
                        .filter(name => name !== "")
                        .sort((a, b) => a.localeCompare(b))

                if (findWallpapers.callback)
                    findWallpapers.callback()

                findWallpapers.callback = null
            }
        }
    }

    function setWallpaper(name: string): void {
        if (name === "")
            return

        const path = root.wallDir + "/" + name

        root.currentWallpaper = path
        wallpaperFile.setText(path)
    }

    Component.onCompleted: root.refresh()
}
