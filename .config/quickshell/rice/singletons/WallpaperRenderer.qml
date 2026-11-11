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
        property int generation: 0

        property string requestedWallpaper: ""

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Background
        color: Theme.background

        function loadWallpaper(path: string): void {
            if (path === "")
                return;

            generation++;
            requestedWallpaper = "file://" + path;

            const next = (imageA.source.toString() === "" && imageB.source.toString() === "") ? 0 : (activeImage === 0 ? 1 : 0);

            pendingImage = next;

            if (next === 0)
                imageA.source = requestedWallpaper;
            else
                imageB.source = requestedWallpaper;
        }

        function imageReady(index: int): void {
            if (pendingImage !== index)
                return;

            const image = index === 0 ? imageA : imageB;

            if (image.status !== Image.Ready)
                return;

            if (image.source.toString() !== requestedWallpaper)
                return;

            // Don't switch until the image has a valid frame.
            if (image.width <= 0 || image.height <= 0)
                return;

            activeImage = index;
            pendingImage = -1;
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
                wallpaperWindow.loadWallpaper( //this is being called
                Wallpaper.currentWallpaper);
            }
        }
    }
}
