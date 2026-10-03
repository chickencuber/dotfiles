//@ pragma UseQApplication

//TASK(20260915-211903-158-n6-315): make some of the windows use LazyLoad

//TASK(20261002-010637-038-n6-346): make the modules work with vertical bars

import Quickshell
import QtQuick
import "command"
import "launcher"
import "wallpaper"
import "screenshot"
import "power"
import "emoji"
import "clipboard"
import "focus"
import "calendar"

import "osd"

import "notifications"

import "applist"
import "tooltip"
import "contextmenu"

import "bar"
import "bar/modules"

import Quickshell.Services.Notifications

Scope {
    Bar {
        id: bar
        thickness: 30
        spacing: 4
        background: null

        left: [
            StartButton {
                size: bar.thickness
            },
            IdleInhibitor {
                size: bar.thickness
                window: bar.window
            },
            HyprlandWindow {
                size: bar.thickness
            }
        ]
        center: [
            HyprlandWorkspace {
                size: bar.thickness
            }
        ]
        right: [
            SystemTray {
                window: bar.window
                size: bar.thickness
                icon_size: 20
            },
            Pulse {
                size: bar.thickness
            },
            Brightness {
                size: bar.thickness
            },
            Battery {
                size: bar.thickness
            },
            Clock {
                size: bar.thickness
                onClicked: calendar.toggle()
            },
            ControlCenter {
                size: bar.thickness
            }
        ]
    }

    AppLists {
        id: applist
    }

    // Bar {
    //     id: bottomBar
    //     position: "bottom"
    //     thickness: 52
    //     onTop: true
    //     fillContents: true
    //     minSize: 50
    //     background: Rectangle {
    //         color: Theme.background.alpha(0.8)
    //         radius: 90
    //         border.color: Theme.accent
    //     }
    //     center: [
    //         AppList {
    //             size: bottomBar.thickness
    //             appLists: applist
    //             tooltip: tooltip
    //             icon_size: 30
    //             contextMenu: contextmenu
    //             background: null
    //         },
    //         Separator{
    //             size: bottomBar.thickness
    //         },
    //         AppList {
    //             mode: "open"
    //             size: bottomBar.thickness
    //             appLists: applist
    //             tooltip: tooltip
    //             icon_size: 30
    //             contextMenu: contextmenu
    //             background: null
    //         }
    //     ]
    // }

    Calendar {
        id: calendar
        marginTop: bar.size + 5
    }

    PowerMenu {}
    AppLauncher {
        appLists: applist
    }
    WallPaper {}
    ScreenShotPicker {}
    EmojiPicker {}
    ClipboardManager {}
    FocusSwitcher {}
    CommandRunner {}

    NotificationCenter {
        id: notificationCenter
        notificationServer: notificationServer
        marginTop: bar.size
    }

    Tooltip {
        id: tooltip
    }
    ContextMenu {
        id: contextmenu 
    }

    VolumeOsd {}
    BrightnessOsd {}
    CapsOsd {}
    NumOsd {}
    MediaOsd {}

    NotificationPopup {
        notificationServer: notificationServer
        notificationCenter: notificationCenter
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: false

        bodySupported: true
        bodyImagesSupported: true
        imageSupported: true

        actionsSupported: true
        actionIconsSupported: true
        inlineReplySupported: true

        onNotification: function (notification) {
            console.log("!!! GOT NOTIFICATION !!!");
            console.log("app:", notification.appName);
            console.log("summary:", notification.summary);
            console.log("body:", notification.body);
            console.log("actions:", notification.actions.length);

            notification.tracked = true;
        }

        Component.onCompleted: {
            console.log("!!! NOTIFICATION SERVER CREATED !!!");
        }
    }
}
