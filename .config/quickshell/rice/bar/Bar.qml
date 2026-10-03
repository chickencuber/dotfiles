import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    property string position: "top"
    property int thickness: 40
    property int spacing: 8
    property bool onTop: false

    readonly property PanelWindow window: root

    property Component background: Component {
        Rectangle {
            color: Theme.background
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.background
    }

    property list<Item> left: []
    property list<Item> center: []
    property list<Item> right: []

    property alias top: root.left
    property alias bottom: root.right
    property alias centre: root.center

    property int edgeMargin: 0
    property int sideMargins: 0
    property int minSize: 0
    property bool fillContents: false

    readonly property int size: thickness + edgeMargin

    readonly property bool horizontal:
        position === "top" || position === "bottom"

    readonly property bool vertical:
        position === "left" || position === "right"

    // ------------------------------------------------------------
    // CONTENT SIZE
    // ------------------------------------------------------------

    readonly property int contentWidth:
        leftRow.implicitWidth +
        centerRow.implicitWidth +
        rightRow.implicitWidth +
        (leftRow.implicitWidth > 0 &&
         centerRow.implicitWidth > 0 ? spacing : 0) +
        (centerRow.implicitWidth > 0 &&
         rightRow.implicitWidth > 0 ? spacing : 0)

    readonly property int contentHeight:
        topColumn.implicitHeight +
        centerColumn.implicitHeight +
        bottomColumn.implicitHeight +
        (topColumn.implicitHeight > 0 &&
         centerColumn.implicitHeight > 0 ? spacing : 0) +
        (centerColumn.implicitHeight > 0 &&
         bottomColumn.implicitHeight > 0 ? spacing : 0)

    // ------------------------------------------------------------
    // WINDOW SIZE
    // ------------------------------------------------------------

    implicitWidth:
        horizontal && fillContents
            ? Math.max(contentWidth, minSize)
            : horizontal
                ? undefined
                : thickness

    implicitHeight:
        vertical && fillContents
            ? Math.max(contentHeight, minSize)
            : vertical
                ? undefined
                : thickness

    // ------------------------------------------------------------
    // PANEL POSITION
    // ------------------------------------------------------------

    anchors {
        top:
            position === "top" ||
            (vertical && !fillContents)

        bottom:
            position === "bottom" ||
            (vertical && !fillContents)

        left:
            position === "left" ||
            (horizontal && !fillContents)

        right:
            position === "right" ||
            (horizontal && !fillContents)
    }

    margins {
        top:
            position === "top"
                ? edgeMargin
                : vertical
                    ? sideMargins
                    : 0

        bottom:
            position === "bottom"
                ? edgeMargin
                : vertical
                    ? sideMargins
                    : 0

        left:
            position === "left"
                ? edgeMargin
                : horizontal
                    ? sideMargins
                    : 0

        right:
            position === "right"
                ? edgeMargin
                : horizontal
                    ? sideMargins
                    : 0
    }

    color: "transparent"

    WlrLayershell.layer:
        onTop ? WlrLayer.Top : WlrLayer.Bottom


    // ============================================================
    // HORIZONTAL
    // ============================================================

    Item {
        id: horizontalContent

        anchors.fill: parent
        visible: root.horizontal

        Row {
            id: leftRow

            y: (parent.height - height) / 2
            x: 0
            spacing: root.spacing

            function child() {
                const items = []

                for (let i = 0; i < root.left.length; ++i)
                    items.push(root.left[i])

                for (const item of items) {
                    item.parent = leftRow

                    item.anchors.left = undefined
                    item.anchors.right = undefined
                    item.anchors.top = undefined
                    item.anchors.bottom = undefined
                    item.anchors.horizontalCenter = undefined
                    item.anchors.verticalCenter = undefined
                }
            }
        }

        Row {
            id: centerRow

            y: (parent.height - height) / 2

            x: root.fillContents
                ? leftRow.width +
                  (leftRow.width > 0 ? root.spacing : 0)
                : (parent.width - width) / 2

            spacing: root.spacing

            function child() {
                const items = []

                for (let i = 0; i < root.center.length; ++i)
                    items.push(root.center[i])

                for (const item of items) {
                    item.parent = centerRow

                    item.anchors.left = undefined
                    item.anchors.right = undefined
                    item.anchors.top = undefined
                    item.anchors.bottom = undefined
                    item.anchors.horizontalCenter = undefined
                    item.anchors.verticalCenter = undefined
                }
            }
        }

        Row {
            id: rightRow

            y: (parent.height - height) / 2

            x: root.fillContents
                ? leftRow.width +
                  centerRow.width +
                  (leftRow.width > 0 ? root.spacing : 0) +
                  (centerRow.width > 0 ? root.spacing : 0)
                : parent.width - width

            spacing: root.spacing

            function child() {
                const items = []

                for (let i = 0; i < root.right.length; ++i)
                    items.push(root.right[i])

                for (const item of items) {
                    item.parent = rightRow

                    item.anchors.left = undefined
                    item.anchors.right = undefined
                    item.anchors.top = undefined
                    item.anchors.bottom = undefined
                    item.anchors.horizontalCenter = undefined
                    item.anchors.verticalCenter = undefined
                }
            }
        }

        Component.onCompleted: {
            if (visible) {
                leftRow.child()
                centerRow.child()
                rightRow.child()
            }
        }
        onVisibleChanged: {
            if (visible) {
                leftRow.child()
                centerRow.child()
                rightRow.child()
            }
        }
    }


    // ============================================================
    // VERTICAL
    // ============================================================

    Item {
        id: verticalContent

        anchors.fill: parent
        visible: root.vertical

        Column {
            id: topColumn

            x: (parent.width - width) / 2
            y: 0
            spacing: root.spacing

            function child() {
                const items = []

                for (let i = 0; i < root.left.length; ++i)
                    items.push(root.left[i])

                for (const item of items) {
                    item.parent = topColumn

                    item.anchors.left = undefined
                    item.anchors.right = undefined
                    item.anchors.top = undefined
                    item.anchors.bottom = undefined
                    item.anchors.horizontalCenter = undefined
                    item.anchors.verticalCenter = undefined
                }
            }
        }

        Column {
            id: centerColumn

            x: (parent.width - width) / 2

            y: root.fillContents
                ? topColumn.height +
                  (topColumn.height > 0 ? root.spacing : 0)
                : (parent.height - height) / 2

            spacing: root.spacing

            function child() {
                const items = []

                for (let i = 0; i < root.center.length; ++i)
                    items.push(root.center[i])

                for (const item of items) {
                    item.parent = centerColumn

                    item.anchors.left = undefined
                    item.anchors.right = undefined
                    item.anchors.top = undefined
                    item.anchors.bottom = undefined
                    item.anchors.horizontalCenter = undefined
                    item.anchors.verticalCenter = undefined
                }
            }
        }

        Column {
            id: bottomColumn

            x: (parent.width - width) / 2

            y: root.fillContents
                ? topColumn.height +
                  centerColumn.height +
                  (topColumn.height > 0 ? root.spacing : 0) +
                  (centerColumn.height > 0 ? root.spacing : 0)
                : parent.height - height

            spacing: root.spacing

            function child() {
                const items = []

                for (let i = 0; i < root.right.length; ++i)
                    items.push(root.right[i])

                for (const item of items) {
                    item.parent = bottomColumn

                    item.anchors.left = undefined
                    item.anchors.right = undefined
                    item.anchors.top = undefined
                    item.anchors.bottom = undefined
                    item.anchors.horizontalCenter = undefined
                    item.anchors.verticalCenter = undefined
                }
            }
        }

        Component.onCompleted: {
            if (visible) {
                topColumn.child()
                centerColumn.child()
                bottomColumn.child()
            }
        }
        onVisibleChanged: {
            if (visible) {
                topColumn.child()
                centerColumn.child()
                bottomColumn.child()
            }
        }
    }
}
