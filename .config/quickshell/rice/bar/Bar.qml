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

    readonly property bool horizontal: position === "top" || position === "bottom"
    readonly property bool vertical: position === "left" || position === "right"

    implicitHeight: horizontal ? thickness : undefined
    implicitWidth: vertical ? thickness : undefined
    anchors {
        top: position === "top" || position === "left" || position === "right"
        bottom: position === "bottom" || position === "left" || position === "right"
        left: position === "top" || position === "bottom" || position === "left"
        right: position === "top" || position === "bottom" || position === "right"
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom

    // ─────────────────────────────────────
    // Horizontal ─────────────────────────────────────

    Item {
        anchors.fill: parent
        visible: root.horizontal

        Row{
            id: leftRow 

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            spacing: root.spacing

            function child() {
                if (!root.horizontal)
                    return;
                const items = [];
                for (let i = 0; i < root.left.length; ++i)
                    items.push(root.left[i]);

                for (const item of items) {
                    item.parent = leftRow;
                    item.anchors.verticalCenter = leftRow.verticalCenter;
                    item.anchors.horizontalCenter = undefined;
                }
            }

            Component.onCompleted: child()
        }

        Row {
            id: centerRow

            anchors.centerIn: parent

            spacing: root.spacing

            function child() {
                if (!root.horizontal)
                    return;
                const items = [];
                for (let i = 0; i < root.center.length; ++i)
                    items.push(root.center[i]);

                for (const item of items) {
                    item.parent = centerRow;
                    item.anchors.verticalCenter = centerRow.verticalCenter;
                    item.anchors.horizontalCenter = undefined;
                }
            }

            Component.onCompleted: child()
        }

        Row{
            id: rightRow

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            spacing: root.spacing

            function child() {
                if (!root.horizontal)
                    return;
                const items = [];
                for (let i = 0; i < root.right.length; ++i)
                    items.push(root.right[i]);

                for (const item of items) {
                    item.parent = rightRow;
                    item.anchors.verticalCenter = rightRow.verticalCenter;
                    item.anchors.horizontalCenter = undefined;
                }
            }

            Component.onCompleted: child()
        }

        onVisibleChanged: {
            if (visible) {
                leftRow.child();
                centerRow.child();
                rightRow.child();
            }
        }
    }
    // ─────────────────────────────────────
    // Vertical
    // ─────────────────────────────────────

    Item {
        anchors.fill: parent
        visible: root.vertical

        Column {
            id: topColumn

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            spacing: root.spacing

            function child() {
                if (!root.vertical)
                    return;
                const items = [];
                for (let i = 0; i < root.left.length; ++i)
                    items.push(root.left[i]);

                for (const item of items) {
                    item.parent = topColumn;
                    item.anchors.horizontalCenter = topColumn.horizontalCenter;
                    item.anchors.verticalCenter = undefined;
                }
            }

            Component.onCompleted: child()
        }

        Column {
            id: centerColumn

            anchors.centerIn: parent

            spacing: root.spacing

            function child() {
                if (!root.vertical)
                    return;
                const items = [];
                for (let i = 0; i < root.center.length; ++i)
                    items.push(root.center[i]);

                for (const item of items) {
                    item.parent = centerColumn;
                    item.anchors.horizontalCenter = centerColumn.horizontalCenter;
                    item.anchors.verticalCenter = undefined;
                }
            }

            Component.onCompleted: child()
        }

        Column {
            id: bottomColumn

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            spacing: root.spacing

            function child() {
                if (!root.vertical)
                    return;
                const items = [];
                for (let i = 0; i < root.right.length; ++i)
                    items.push(root.right[i]);

                for (const item of items) {
                    item.parent = bottomColumn;
                    item.anchors.horizontalCenter = bottomColumn.horizontalCenter;
                    item.anchors.verticalCenter = undefined;
                }
            }

            Component.onCompleted: child()
        }

        onVisibleChanged: {
            if (visible) {
                topColumn.child();
                centerColumn.child();
                bottomColumn.child();
            }
        }
    }
}
