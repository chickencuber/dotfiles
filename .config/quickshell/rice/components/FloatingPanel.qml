pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Wayland
import Quickshell
import QtQuick
import "../singletons/"

Scope {
    id: root

    property bool open: false

    property int keyboardFocus: WlrKeyboardFocus.Exclusive
    property int width: 400
    property int height: 400
    property color background: Theme.background

    default property list<Item> data

    property int marginTop: 0
    property int marginBottom: 0
    property int marginLeft: 0
    property int marginRight: 0

    property bool interactive: true
    property bool preventClose: true
    property bool touchOutside: true
    property bool closeOnEsc: true

    SimpleAnchors {
        id: panelAnchors
    }
    property alias anchors: panelAnchors

    signal animationFinished(bool opening)
    signal ran

    enum Origin {
        TopLeft,
        Center,
        Mouse
    }

    enum RestrictMode {
        None,
        Flip,
        Clamp
    }

    property int restrict: FloatingPanel.None
    property string ipc: ""
    property int origin: FloatingPanel.TopLeft

    property int x: 0
    property int y: 0

    property point mousePosition: Qt.point(0, 0)
    readonly property var screen: Quickshell.screens[0]

    property PanelAnimation on_open: PanelAnimation {}
    property PanelAnimation on_close: PanelAnimation {}

    // Animation state
    property real animationX: 0
    property real animationY: 0
    property real animationWidth: 0
    property real animationHeight: 0
    property real animationOpacity: 1

    property int activeDuration: 200
    property int activeEasing: Easing.OutCubic

    property real animationStartX: 0
    property real animationStartY: 0
    property real animationStartWidth: 0
    property real animationStartHeight: 0
    property real animationStartOpacity: 1

    property real animationEndX: 0
    property real animationEndY: 0
    property real animationEndWidth: 0
    property real animationEndHeight: 0
    property real animationEndOpacity: 1

    readonly property int calculatedWidth: {
        if (root.anchors.left && root.anchors.right)
            return Math.max(0, screen.width - marginLeft - marginRight);

        return width;
    }

    readonly property int calculatedHeight: {
        if (root.anchors.top && root.anchors.bottom)
            return Math.max(0, screen.height - marginTop - marginBottom);

        return height;
    }

    readonly property int calculatedX: {
        if (root.anchors.left)
            return marginLeft;

        if (root.anchors.right)
            return screen.width - calculatedWidth - marginRight;

        let nx = (() => {
                switch (origin) {
                case FloatingPanel.TopLeft:
                    return x;
                case FloatingPanel.Mouse:
                    return mousePosition.x + x;
                case FloatingPanel.Center:
                    return screen.width / 2 + x - calculatedWidth / 2;
                }
                return x;
            })();

        switch (restrict) {
        case FloatingPanel.Clamp:
            nx = Math.max(0, Math.min(nx, screen.width - calculatedWidth));
            break;
        case FloatingPanel.Flip:
            if (origin === FloatingPanel.Mouse && nx + calculatedWidth > screen.width)
                nx = mousePosition.x - calculatedWidth - x;
            break;
        }

        if (restrict !== FloatingPanel.None)
            nx = Math.max(marginLeft, Math.min(nx, screen.width - calculatedWidth - marginRight));

        return nx;
    }

    readonly property bool needFlipH: restrict === FloatingPanel.Flip && origin === FloatingPanel.Mouse && mousePosition.x + x + calculatedWidth > screen.width

    readonly property bool needFlipV: restrict === FloatingPanel.Flip && origin === FloatingPanel.Mouse && mousePosition.y + y + calculatedHeight > screen.height
    readonly property int calculatedY: {
        if (root.anchors.top)
            return marginTop;

        if (root.anchors.bottom)
            return screen.height - calculatedHeight - marginBottom;

        let ny = (() => {
                switch (origin) {
                case FloatingPanel.TopLeft:
                    return y;
                case FloatingPanel.Mouse:
                    return mousePosition.y + y;
                case FloatingPanel.Center:
                    return screen.height / 2 + y - calculatedHeight / 2;
                }
                return y;
            })();

        switch (restrict) {
        case FloatingPanel.Clamp:
            ny = Math.max(0, Math.min(ny, screen.height - calculatedHeight));
            break;
        case FloatingPanel.Flip:
            if (origin === FloatingPanel.Mouse && ny + calculatedHeight > screen.height)
                ny = mousePosition.y - calculatedHeight - y;
            break;
        }

        if (restrict !== FloatingPanel.None)
            ny = Math.max(marginTop, Math.min(ny, screen.height - calculatedHeight - marginBottom));

        return ny;
    }

    function playTransition(opening: bool): void {
        transition.stop();

        const config = opening ? on_open : on_close;
        const type = config.type;

        activeDuration = config.animationDuration;
        activeEasing = config.animationEasing;

        animationStartX = 0;
        animationStartY = 0;
        animationStartWidth = 0;
        animationStartHeight = 0;
        animationStartOpacity = 1;

        animationEndX = 0;
        animationEndY = 0;
        animationEndWidth = 0;
        animationEndHeight = 0;
        animationEndOpacity = 1;

        const w = calculatedWidth;
        const h = calculatedHeight;

        switch (type) {
        case PanelAnimation.Left:
            animationStartX = opening ? -calculatedX - w : 0;
            animationEndX = opening ? 0 : -calculatedX - w;
            break;
        case PanelAnimation.Right:
            animationStartX = opening ? screen.width - calculatedX : 0;
            animationEndX = opening ? 0 : screen.width - calculatedX;
            break;
        case PanelAnimation.Top:
            animationStartY = opening ? -calculatedY - h : 0;
            animationEndY = opening ? 0 : -calculatedY - h;
            break;
        case PanelAnimation.Bottom:
            animationStartY = opening ? screen.height - calculatedY : 0;
            animationEndY = opening ? 0 : screen.height - calculatedY;
            break;
        case PanelAnimation.DrawerFromTop:
            animationStartHeight = opening ? -h : 0;
            animationEndHeight = opening ? 0 : -h;
            break;
        case PanelAnimation.DrawerFromBottom:
            animationStartHeight = opening ? -h : 0;
            animationEndHeight = opening ? 0 : -h;
            animationStartY = opening ? h : 0;
            animationEndY = opening ? 0 : h;
            break;
        case PanelAnimation.DrawerFromLeft:
            animationStartWidth = opening ? -w : 0;
            animationEndWidth = opening ? 0 : -w;
            break;
        case PanelAnimation.DrawerFromRight:
            animationStartWidth = opening ? -w : 0;
            animationEndWidth = opening ? 0 : -w;
            animationStartX = opening ? w : 0;
            animationEndX = opening ? 0 : w;
            break;
        case PanelAnimation.Fade:
            animationStartOpacity = opening ? 0 : 1;
            animationEndOpacity = opening ? 1 : 0;
            break;
        }

        animationX = animationStartX;
        animationY = animationStartY;
        animationWidth = animationStartWidth;
        animationHeight = animationStartHeight;
        animationOpacity = animationStartOpacity;

        if (type === PanelAnimation.None || activeDuration <= 0) {
            animationX = animationEndX;
            animationY = animationEndY;
            animationWidth = animationEndWidth;
            animationHeight = animationEndHeight;
            animationOpacity = animationEndOpacity;

            root.animationFinished(opening);
            if (!opening)
                lazy.active = false;

            return;
        }

        transition.start();
    }

    onOpenChanged: {
        Qt.callLater(() => {
            if (open) {
                ShellContext.wm.updateCursorPosition(() => {
                    if (!open)
                        return;

                    mousePosition = ShellContext.wm.cursorPosition;
                    lazy.active = true;

                    Qt.callLater(() => {
                        if (open)
                            playTransition(true);
                    });
                });
            } else {
                if (lazy.active)
                    playTransition(false);
            }
        });
    }

    ParallelAnimation {
        id: transition

        NumberAnimation {
            target: root
            property: "animationX"
            from: root.animationStartX
            to: root.animationEndX
            duration: root.activeDuration
            easing.type: root.activeEasing
        }

        NumberAnimation {
            target: root
            property: "animationY"
            from: root.animationStartY
            to: root.animationEndY
            duration: root.activeDuration
            easing.type: root.activeEasing
        }

        NumberAnimation {
            target: root
            property: "animationWidth"
            from: root.animationStartWidth
            to: root.animationEndWidth
            duration: root.activeDuration
            easing.type: root.activeEasing
        }

        NumberAnimation {
            target: root
            property: "animationHeight"
            from: root.animationStartHeight
            to: root.animationEndHeight
            duration: root.activeDuration
            easing.type: root.activeEasing
        }

        NumberAnimation {
            target: root
            property: "animationOpacity"
            from: root.animationStartOpacity
            to: root.animationEndOpacity
            duration: root.activeDuration
            easing.type: root.activeEasing
        }

        onFinished: {
            root.animationFinished(root.open);
            if (!root.open)
                lazy.active = false;
        }
    }

    LazyLoader {
        active: root.ipc !== ""

        IpcHandler {
            target: root.ipc

            function toggle(): void {
                root.open = !root.open;
            }

            function close(): void {
                root.open = false;
            }

            function open(): void {
                root.open = true;
            }
            function run(): void {
                root.ran();
            }
        }
    }

    LazyLoader {
        id: lazy

        PanelWindow {
            color: "transparent"
            mask: Region {
                item: root.interactive ? root.touchOutside ? outsideMouseArea : rect : null
            }

            anchors {
                bottom: true
                top: true
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.interactive ? root.keyboardFocus : WlrKeyboardFocus.None
            WlrLayershell.exclusiveZone: -1

            MouseArea {
                id: outsideMouseArea
                enabled: root.interactive && root.touchOutside
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                anchors.fill: parent

                onClicked: {
                    root.open = false;
                }
            }

            FocusScope {
                anchors.fill: parent
                enabled: root.interactive

                Keys.onEscapePressed: {
                    root.open = false;
                }

                focus: root.interactive && root.closeOnEsc
            }

            MouseArea {
                enabled: root.interactive && root.preventClose
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                anchors.fill: rect

                onClicked: mouse => mouse.accepted = true
            }

            Rectangle {
                id: rect

                clip: true

                x: root.calculatedX + root.animationX
                y: root.calculatedY + root.animationY
                width: Math.max(0, root.calculatedWidth + root.animationWidth)
                height: Math.max(0, root.calculatedHeight + root.animationHeight)

                opacity: root.animationOpacity
                color: root.background
                data: root.data
            }
        }
    }
}
