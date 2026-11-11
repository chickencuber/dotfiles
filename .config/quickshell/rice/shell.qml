import QtQuick
import "./panels"
import "./bar_modules"
import "./components/"
import "./services/wms"
import "./singletons/"
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
                    PowerMenu.open = true
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
            Pulse {},
            Brightness {},
            Battery {},
            Time {
                onClicked: {
                    Calendar.visible = true
                }
            },
            BarIconButton {
                name: "notifications"
                filled: true
                onClicked: {
                    NotificationCenter.visible = true
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
