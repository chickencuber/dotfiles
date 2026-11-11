pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services/"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: wallpaperWindow

        required property var modelData
        screen: modelData

        property int activeImage: 0
        property int pendingImage: -1
        property bool switching: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Background
        color: "black"

        function loadWallpaper(path: string): void {
            if (path === "")
                return;
            const next = activeImage === 0 ? 1 : 0;

            pendingImage = next;
            switching = true;

            if (next === 0)
                imageA.source = "file://" + path;
            else
                imageB.source = "file://" + path;
        }

        function imageReady(index: int): void {
            if (!switching || pendingImage !== index)
                return;
            activeImage = index;
            pendingImage = -1;
            switching = false;
        }

        AnimatedImage {
            id: imageA

            anchors.fill: parent

            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: true
            smooth: true

            opacity: wallpaperWindow.activeImage === 0 ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.InOutCubic
                }
            }

            onStatusChanged: {
                if (status === AnimatedImage.Ready)
                    wallpaperWindow.imageReady(0);
            }
        }

        AnimatedImage {
            id: imageB

            anchors.fill: parent

            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: true
            smooth: true

            opacity: wallpaperWindow.activeImage === 1 ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.InOutCubic
                }
            }

            onStatusChanged: {
                if (status === AnimatedImage.Ready)
                    wallpaperWindow.imageReady(1);
            }
        }

        Connections {
            target: Wallpaper

            function onCurrentWallpaperChanged(): void {
                wallpaperWindow.loadWallpaper(Wallpaper.currentWallpaper);
            }
        }

        Component.onCompleted: {
            if (Wallpaper.currentWallpaper !== "") {
                imageA.source = "file://" + Wallpaper.currentWallpaper;
            }
        }
    }
}
