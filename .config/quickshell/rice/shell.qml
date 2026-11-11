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
                    color: Theme.background.alpha(0.45)
                }

                // CLOCK

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - 260

                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: Qt.formatDateTime(clock.now, "h:mm")
                        color: Theme.text

                        font.family: Theme.font
                        font.pixelSize: 95
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: Qt.formatDate(clock.now, "dddd, MMMM dd")
                        color: Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 22
                    }
                }

                // PROFILE + PASSWORD

                Column {
                    anchors.centerIn: parent
                    spacing: 16

                    Item {
                        width: 100
                        height: 100

                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            id: profileImage
                            anchors.fill: parent

                            source: "file:///var/lib/AccountsService/icons/" + Quickshell.env("USER")
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                        }

                        Rectangle {
                            id: profileMask
                            anchors.fill: parent
                            radius: width / 2
                            color: "white"
                            visible: false
                        }

                        ShaderEffectSource {
                            id: profileMaskSource
                            sourceItem: profileMask
                            hideSource: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: profileImage

                            maskEnabled: true
                            maskSource: profileMaskSource
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.accent
                        }
                    }

                    // PASSWORD INPUT

                    Rectangle {
                        width: 250
                        height: 60

                        radius: 10
                        color: Theme.surface.alpha(0.5)

                        border.width: 2
                        border.color: Theme.accent

                        TextInput {
                            id: passwordField

                            anchors.fill: parent
                            anchors.margins: 8

                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentText

                            font.family: Theme.font
                            font.pixelSize: 18
                            font.letterSpacing: 1.5

                            echoMode: TextInput.Password
                            passwordCharacter: "●"

                            enabled: !lock.authenticating

                            onTextEdited: lock.password = text
                            onAccepted: lock.authenticate()

                            Component.onCompleted: forceActiveFocus()

                            Connections {
                                target: lock

                                function onPasswordChanged() {
                                    if (passwordField.text !== lock.password)
                                        passwordField.text = lock.password;
                                }
                            }
                        }
                    }

                    // STATUS

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: lock.authenticating ? "Authenticating..." : lock.message || "Input Password..."

                        color: lock.messageIsError ? Theme.accent : Theme.textMuted

                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                // CLOCK UPDATE

                QtObject {
                    id: clock

                    property date now: new Date()
                }
                Timer {
                    interval: 1000
                    running: true
                    repeat: true

                    onTriggered: clock.now = new Date()
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
