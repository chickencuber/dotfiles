import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../bar_modules/"
import "../singletons"

PanelWindow {
    id: root

    enum Side {
        Top,
        Bottom
    }

    color: "transparent"

    property int position: HorizontalBar.Top
    property int thickness: 40
    property int spacing: 8
    property bool onTop: false

    property Component background: Component {
        Rectangle {
            color: Theme.background
        }
    }

    property Component left_background: null
    property Component right_background: null
    property Component center_background: null

    property alias centre_background: root.center_background

    property list<Module> left: []
    property list<Module> center: []
    property alias centre: root.center
    property list<Module> right: []

    property int edgeMargin: 0
    property int sideMargins: 0
    property int minSize: 0
    property bool fillContents: false

    readonly property int size: thickness + edgeMargin

    readonly property int contentSize: leftLayout.implicitWidth + centerLayout.implicitWidth + rightLayout.implicitWidth + (leftLayout.implicitWidth > 0 && centerLayout.implicitWidth > 0 ? spacing : 0) + (centerLayout.implicitWidth > 0 && rightLayout.implicitWidth > 0 ? spacing : 0)

    implicitWidth: fillContents ? Math.max(contentSize + sideMargins * 2, minSize) : undefined

    implicitHeight: thickness

    anchors {
        top: position === HorizontalBar.Top
        bottom: position === HorizontalBar.Bottom
        left: !fillContents
        right: !fillContents
    }

    margins {
        top: position === HorizontalBar.Top ? edgeMargin : 0
        bottom: position === HorizontalBar.Bottom ? edgeMargin : 0
        left: fillContents ? 0 : sideMargins
        right: fillContents ? 0 : sideMargins
    }

    WlrLayershell.layer: onTop ? WlrLayer.Top : WlrLayer.Bottom

    Loader {
        anchors.fill: parent
        sourceComponent: root.background
    }

    Item {
        anchors.fill: parent

        Item {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }

            width: leftLayout.implicitWidth

            Loader {
                anchors.fill: parent
                sourceComponent: root.left_background
            }

            RowLayout {
                id: leftLayout

                anchors {
                    left: parent.left
                    leftMargin: root.sideMargins
                    verticalCenter: parent.verticalCenter
                }

                spacing: root.spacing
            }
        }

        Item {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            width: rightLayout.implicitWidth

            Loader {
                anchors.fill: parent
                sourceComponent: root.right_background
            }

            RowLayout {
                id: rightLayout

                anchors {
                    right: parent.right
                    rightMargin: root.sideMargins
                    verticalCenter: parent.verticalCenter
                }

                spacing: root.spacing
            }
        }

        Item {
            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            width: centerLayout.implicitWidth

            x: root.fillContents
            ? leftLayout.implicitWidth + (
                parent.width
                - leftLayout.implicitWidth
                - rightLayout.implicitWidth
                - width
            ) / 2
            : (parent.width - width) / 2

            Loader {
                anchors.fill: parent
                sourceComponent: root.center_background
            }

            RowLayout {
                id: centerLayout

                anchors.centerIn: parent
                spacing: root.spacing
            }
        }
    }

    function registerModules(modules, layout) {
        for (const module of modules) {
            module.parent = layout;
            module.bar = root;
            module.bar_side = position === HorizontalBar.Top ? Module.Top : Module.Bottom;
        }
    }

    Component.onCompleted: {
        registerModules(root.left, leftLayout);
        registerModules(root.center, centerLayout);
        registerModules(root.right, rightLayout);
    }
}
