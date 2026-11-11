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

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Background
        color: Theme.background

        AnimatedImage {
            id: wallpaperImage

            anchors.fill: parent

            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            playing: true

            source: Wallpaper.currentWallpaper !== "" ? "file://" + Wallpaper.currentWallpaper : ""

            onStatusChanged: {
                if (status === Image.Error) {
                    console.error("Failed to load wallpaper:", source);
                }
            }
        }
        Image {
            id: incoming

            anchors.fill: parent

            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            visible: false
            opacity: 0

            onStatusChanged: {
                if (status === Image.Error) {
                    console.error("Failed to load wallpaper:", source);
                } else if (status === Image.Ready) {
                    visible = true;
                    crossfade.start();
                }
            }
        }
        ParallelAnimation {
            id: crossfade

            NumberAnimation {
                target: wallpaperImage
                property: "opacity"
                to: 0
                duration: 500
                easing.type: Easing.InOutCubic
            }

            NumberAnimation {
                target: incoming
                property: "opacity"
                to: 1
                duration: 500
                easing.type: Easing.InOutCubic
            }

            onFinished: {
                // Swap the sources
                wallpaperImage.source = incoming.source;
                wallpaperImage.playing = true;

                wallpaperImage.opacity = 1;

                // Hide and reset the incoming image
                incoming.opacity = 0;
                incoming.visible = false;
            }
        }
        function applyWallpaper(current) {
            incoming.source = current !== "" ? "file://" + current : "";
        }

        Connections {
            target: Wallpaper
            function onCurrentWallpaperChanged(): void {
                wallpaperWindow.applyWallpaper(Wallpaper.currentWallpaper);
            }
        }
    }
}
