pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../singletons/"

Item {
    id: root

    property bool locked: false
    property string pamConfig: "login"
    property string password: ""
    property int fadeDuration: 400

    property Component content

    readonly property bool authenticating: pam.active
    readonly property string message: pam.message
    readonly property bool messageIsError: pam.messageIsError

    property bool unlocking: false

    function authenticate(): void {
        if (password.length > 0 && !pam.active)
            pam.start();
    }

    function reset(): void {
        password = "";
    }

    function beginUnlock(): void {
        unlocking = true;
        unlockTimer.start();
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.reset();
            root.unlocking = false;
            root.locked = true;
        }
    }

    PamContext {
        id: pam

        config: root.pamConfig

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.reset();

            if (result === PamResult.Success)
                root.beginUnlock();
        }
    }

    Timer {
        id: unlockTimer

        interval: root.fadeDuration

        onTriggered: {
            root.unlocking = false;
            root.locked = false;
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: root.locked

        WlSessionLockSurface {
            color: "transparent"

            Item {
                id: contentContainer

                anchors.fill: parent

                opacity: root.unlocking ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.fadeDuration
                        easing.type: Easing.InOutCubic
                    }
                }

                Rectangle {
                    color: Theme.background
                    anchors.fill: parent
                    Loader {
                        anchors.fill: parent
                        sourceComponent: root.content
                    }
                }
            }

            // Fade in when the lock is activated.
            Connections {
                target: root

                function onLockedChanged(): void {
                    if (root.locked && !root.unlocking)
                        contentContainer.opacity = 0;
                }
            }

            NumberAnimation {
                id: fadeIn

                target: contentContainer
                property: "opacity"
                from: 0
                to: 1

                duration: root.fadeDuration
                easing.type: Easing.OutCubic

                running: root.locked && !root.unlocking
            }
        }
    }
}
