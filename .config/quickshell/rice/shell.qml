pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Effects
import "./panels"
import "./bar_modules"
import "./components/"
import "./services/wms"
import "./singletons/"
import "./services/"
import "./applets/"

Entry {
    wm: Hyprland
    HorizontalBar {
        id: bar
        thickness: 30
        spacing: 4
        background: null
        left: [
            BarIconButton {
                name: "archlinux-logo"
                source: Icon.System
                monochrome: true
                onClicked: {
                    PowerMenu.open = true;
                }
            },
            IdleInhibitor {},
            Window {}
        ]
        center: [
            Workspaces {}
        ]
        right: [
            SystemTray {},
            Pulse {
                onClicked: {
                    Quickshell.execDetached("pavucontrol");
                }
            },
            Brightness {},
            Battery {},
            Time {
                onClicked: {
                    Calendar.visible = true;
                }
            },
            BarIconButton {
                name: "notifications"
                filled: true
                onClicked: {
                    NotificationCenter.visible = true;
                }
            }
        ]
    }

    /*
     HorizontalBar{
         id: bottomBar
         position: HorizontalBar.Bottom
         thickness: 52
         onTop: true
         fillContents: true
         minSize: 50
         background: Rectangle {
             color: Theme.background.alpha(0.8)
             radius: 90
             border.color: Theme.accent
         }
         center: [
             BarAppList {
                 icon_size: 30
                 background: null
             },
             BarSep{},
             BarAppList {
                 mode: BarAppList.Open
                 icon_size: 30
                 background: null
             }
         ]
     }
     /**/

     //TASK(20261111-000211-591-n6-797): extract out some of the simple things(like clock and password input) into its own component
     LockScreen {
         id: lock

         content: Component {
             Rectangle {
                 anchors.fill: parent
                 color: Theme.background

                 // WALLPAPER

                 AnimatedImage {
                     id: wallpaperBackground

                     anchors.fill: parent

                     source: Wallpaper.currentWallpaper
                     fillMode: Image.PreserveAspectCrop

                     asynchronous: true
                     cache: false
                     playing: !lock.unlocking
                     loops: Animation.Infinite
                     smooth: true
                 }

                 // BLURRED WALLPAPER

                 MultiEffect {
                     anchors.fill: wallpaperBackground
                     source: wallpaperBackground

                     blurEnabled: true
                     blur: 1.0
                     blurMax: 32
                 }

                 // DARKEN BACKGROUND

                 Rectangle {
                     anchors.fill: parent
                     color: Theme.dark.alpha(0.45)
                 }


                 // PROFILE + PASSWORD

                 Column {
                     anchors.centerIn: parent
                     spacing: 16

                     LockClock{
                         format: "hh:mm AP"
                         anchors.horizontalCenter: parent.horizontalCenter
                     }
                     LockProfile {
                         anchors.horizontalCenter: parent.horizontalCenter
                     }

                     // PASSWORD INPUT

                     LockPassword {
                         lockScreen: lock
                         anchors.horizontalCenter: parent.horizontalCenter
                     }

                     // STATUS

                     LockStatus {
                         lockScreen: lock
                         anchors.horizontalCenter: parent.horizontalCenter
                     }
                 }
             }
         }
     }

     Binding {
         target: NotificationCenter
         property: "marginTop"
         value: bar.size
     }
     Binding {
         target: Calendar
         property: "marginTop"
         value: bar.size
     }
 }
