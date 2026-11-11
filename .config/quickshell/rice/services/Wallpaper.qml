//TASK(20261110-182255-069-n6-963): make this also handle rendering wallpapers and not rely on awww
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property string wallDir:
        Quickshell.env("HOME") + "/.config/hypr/walls"

    property string wallPath:
        Quickshell.env("HOME") + "/.config/hypr/wall"

    property string thumbnailPath:
        Quickshell.env("HOME") + "/.config/hypr/thumbnail.png"

    // =========================================================
    // STATE
    // =========================================================

    property list<string> wallpapers: []

    property string currentWallpaper: ""

    property bool applying: false

    property string pendingWallpaper: ""

    // =========================================================
    // GET WALLPAPERS
    // =========================================================

    function refresh(callback = ()=>{}): void {
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

                if (output === "") {
                    root.wallpapers = []
                    return
                }

                root.wallpapers = output
                    .split("\n")
                    .filter(name => name !== "")
                    .sort((a, b) => a.localeCompare(b))
                if(findWallpapers.callback) findWallpapers.callback()
                findWallpapers.callback = null;
            }
        }
    }

    // =========================================================
    // SET WALLPAPER
    // =========================================================

    function setWallpaper(name: string): void {
        if (root.applying || name === "")
            return

        root.applying = true
        root.pendingWallpaper = name

        copyWallpaper.command = [
            "cp",
            root.wallDir + "/" + name,
            root.wallPath
        ]

        copyWallpaper.running = true
    }

    Process {
        id: copyWallpaper

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.applying = false
                root.pendingWallpaper = ""
                return
            }

            createThumbnail.running = true
        }
    }

    Process {
        id: createThumbnail

        command: [
            "ffmpeg",
            "-y",
            "-i", root.wallPath,
            "-vf", "scale=200:-1",
            "-vframes", "1",
            root.thumbnailPath
        ]

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.applying = false
                root.pendingWallpaper = ""
                return
            }

            clearCache.running = true
        }
    }

    Process {
        id: clearCache

        command: ["awww", "clear-cache"]

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.applying = false
                root.pendingWallpaper = ""
                return
            }

            setWallpaperProcess.running = true
        }
    }

    Process {
        id: setWallpaperProcess

        command: [
            "awww",
            "img",
            root.wallPath,
            "--transition-type", "fade",
            "--transition-duration", "1"
        ]

        onExited: exitCode => {
            if (exitCode === 0)
                root.currentWallpaper = root.pendingWallpaper

            root.applying = false
            root.pendingWallpaper = ""
        }
    }

    // =========================================================
    // INITIALIZATION
    // =========================================================

    Component.onCompleted: {
        root.refresh()
    }
}
