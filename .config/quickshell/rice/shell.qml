//@ pragma UseQApplication

//TASK(20260915-211903-158-n6-315): make some of the windows use LazyLoad

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

import "osd"

import "notifications"

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
            },
            ControlCenter {
                size: bar.thickness
            }
        ]
    }


    PowerMenu {}
    AppLauncher {}
    WallPaper {}
    ScreenShotPicker {}
    EmojiPicker {}
    ClipboardManager {}
    FocusSwitcher {}
    CommandRunner {}

    NotificationCenter {
        id: notificationCenter
        notificationServer: notificationServer
        marginTop: bar.thickness
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
