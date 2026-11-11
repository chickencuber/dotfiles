pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../singletons/"

Item {
    id: root

    anchors.fill: parent
    required property Item target

    property string text: ""
    property int delay: 400
    property int offset: 12
    property int padding: 8

    property point cursorPosition: Qt.point(0, 0)
    property var targetScreen: null

    function showTooltip(): void {
        if (!hoverHandler.hovered || text === "")
            return;

        if (ShellContext.wm && typeof ShellContext.wm.updateCursorPosition === "function") {
            ShellContext.wm.updateCursorPosition(() => {
                resolveAndShowTooltip();
            });
        } else {
            resolveAndShowTooltip();
        }
    }

    function resolveAndShowTooltip(): void {
        if (!hoverHandler.hovered || text === "")
            return;

        const position = ShellContext.wm && ShellContext.wm.cursorPosition
            ? ShellContext.wm.cursorPosition
            : Qt.point(0, 0);

        const screens = Quickshell.screens;
        let screen = screens.length > 0 ? screens[0] : null;

        for (let i = 0; i < screens.length; i++) {
            const current = screens[i];

            if (
                position.x >= current.x &&
                position.x < current.x + current.width &&
                position.y >= current.y &&
                position.y < current.y + current.height
            ) {
                screen = current;
                break;
            }
        }

        if (screen === null)
            return;

        targetScreen = screen;
        cursorPosition = Qt.point(position.x - screen.x, position.y - screen.y);

        tooltipPanel.open = true;
    }

    HoverHandler {
        id: hoverHandler
        parent: root.target
        blocking: false

        onHoveredChanged: {
            if (hovered)
            showTimer.restart()
            else {
                showTimer.stop()
                tooltipPanel.open = false
            }
        }
    }

    onTextChanged: {
        if (text === "") {
            showTimer.stop();
            tooltipPanel.open = false;
        }
    }

    Timer {
        id: showTimer
        interval: root.delay
        repeat: false
        onTriggered: root.showTooltip()
    }

    FloatingPanel {
        id: tooltipPanel

        origin: FloatingPanel.Mouse
        restrict: FloatingPanel.Flip
        interactive: false

        width: tooltipText.implicitWidth + root.padding * 2
        height: tooltipText.implicitHeight + root.padding * 2
        x: width / -2
        y: height * -1.5

        Rectangle {
            id: tooltipContent

            anchors.fill: parent
            color: Theme.background
            radius: 8

            border {
                width: 1
                color: Theme.accent
            }

            Text {
                id: tooltipText

                anchors.centerIn: parent
                text: root.text
                color: Theme.text

                font {
                    family: Theme.font
                    pixelSize: 12
                }
            }
        }
    }
}
