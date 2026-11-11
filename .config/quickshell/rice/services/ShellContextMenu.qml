pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell

import "../singletons/"
import "../components/"

Scope {
    id: root

    property alias isOpen: panel.open

    property Item target: null
    property var items: []
    property var nativeMenu: null

    readonly property bool nativeMode: nativeMenu !== null

    property int popupMargin: 12
    property int menuWidth: 196
    property int itemWidth: 180
    property int itemHeight: 32
    property int maxHeight: 350

    readonly property int maxMenuHeight: Math.max(80, Math.min(maxHeight, panel.screen.height - 32))

    // Root menu
    FloatingPanel {
        id: panel

        origin: FloatingPanel.Mouse
        restrict: FloatingPanel.Flip

        x: root.popupMargin
        y: root.popupMargin

        width: root.menuWidth
        height: root.nativeMode ? Math.max(32, nativeRoot.item ? nativeRoot.item.implicitHeight : 32) : Math.max(32, customRoot.item ? customRoot.item.implicitHeight : 32)

        background: "transparent"

        on_open.type: needFlipV ? PanelAnimation.DrawerFromBottom : PanelAnimation.DrawerFromTop
        on_close.type: needFlipV ? PanelAnimation.DrawerFromBottom : PanelAnimation.DrawerFromTop

        onOpenChanged: {
            if (!open) {
                target = null;
                root.items = [];
                root.nativeMenu = null;
            }
        }

        Item {
            anchors.fill: parent

            Loader {
                id: customRoot

                anchors.fill: parent

                active: !root.nativeMode
                sourceComponent: customMenuLevelComponent

                property var menuItems: root.items
                property var rootMenu: root

                onLoaded: {
                    if (item) {
                        item.menuItems = menuItems;
                        item.rootMenu = rootMenu;
                    }
                }

                onMenuItemsChanged: {
                    if (item)
                        item.menuItems = menuItems;
                }
            }

            Loader {
                id: nativeRoot

                anchors.fill: parent

                active: root.nativeMode
                sourceComponent: nativeMenuLevelComponent

                property var menuHandle: root.nativeMenu

                onLoaded: {
                    if (item) {
                        item.menuHandle = menuHandle;
                        item.rootMenu = root;
                    }
                }

                onMenuHandleChanged: {
                    if (item)
                        item.menuHandle = menuHandle;
                }
            }
        }
    }

    // Recursive custom menu contents.
    Component {
        id: customMenuLevelComponent

        Item {
            id: level

            property var menuItems: []
            property var rootMenu: null
            property Item activeItem: null

            readonly property int maxHeight: rootMenu ? rootMenu.maxMenuHeight : 350

            width: root.menuWidth
            implicitWidth: root.menuWidth

            implicitHeight: customFlickable.height + 12
            height: implicitHeight

            Rectangle {
                anchors.fill: parent

                color: Theme.background
                border.color: Theme.accent.alpha(0.25)
                border.width: 1

                Flickable {
                    id: customFlickable

                    anchors.centerIn: parent

                    width: root.itemWidth
                    height: Math.max(0, Math.min(customColumn.implicitHeight, level.maxHeight - 12))

                    contentWidth: width
                    contentHeight: customColumn.implicitHeight

                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: customColumn

                        width: customFlickable.width
                        spacing: 2

                        Repeater {
                            model: level.menuItems

                            delegate: Item {
                                id: customItem

                                required property var modelData

                                readonly property bool separator: !!(modelData && modelData.separator === true)
                                readonly property bool hasSubmenu: !!(modelData && modelData.children && modelData.children.length > 0)

                                width: root.itemWidth
                                height: separator ? 7 : root.itemHeight

                                Rectangle {
                                    visible: customItem.separator

                                    anchors.centerIn: parent

                                    width: 150
                                    height: 1

                                    color: Theme.text.alpha(0.1)
                                }

                                Rectangle {
                                    visible: !customItem.separator

                                    anchors.fill: parent
                                    radius: 8

                                    color: customItemMouse.containsMouse ? Theme.accent.alpha(0.18) : "transparent"

                                    Row {
                                        anchors.fill: parent

                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10

                                        spacing: 8

                                        Text {
                                            id: customLabel

                                            width: parent.width - 24

                                            anchors.verticalCenter: parent.verticalCenter

                                            text: customItem.modelData.text ?? ""
                                            color: customItem.modelData.color ?? Theme.text

                                            font.family: Theme.font
                                            font.pixelSize: 12
                                            font.bold: true

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: customItem.hasSubmenu

                                            anchors.verticalCenter: parent.verticalCenter

                                            text: "›"
                                            color: Theme.text
                                            font.pixelSize: 18
                                        }
                                    }

                                    MouseArea {
                                        id: customItemMouse

                                        anchors.fill: parent

                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        enabled: !customItem.separator

                                        onEntered: {
                                            if (customItem.hasSubmenu) {
                                                level.activeItem = customItem;
                                            } else {
                                                level.activeItem = null;
                                            }
                                        }

                                        onClicked: {
                                            if (customItem.hasSubmenu)
                                                return;

                                            if (customItem.modelData.action)
                                                customItem.modelData.action();

                                            if (level.rootMenu)
                                                level.rootMenu.close();
                                        }
                                    }

                                    ToolTip {
                                        target: customItemMouse
                                        text: customLabel.truncated ? customLabel.text : ""
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: customFlickable.contentHeight > customFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

                        width: 6

                        background: Rectangle {
                            color: "transparent"
                        }

                        contentItem: Rectangle {
                            radius: 3
                            color: Theme.accent
                        }
                    }
                }
            }

            // Single shared submenu panel for this level (fixes nesting/positioning bugs)
            FloatingPanel {
                id: customSubmenuPanel

                open: level.rootMenu !== null && level.rootMenu.isOpen && level.activeItem !== null && level.activeItem.hasSubmenu

                touchOutside: false

                origin: FloatingPanel.TopLeft
                restrict: FloatingPanel.Flip

                on_open.type: needFlipV ? PanelAnimation.DrawerFromBottom : PanelAnimation.DrawerFromTop
                on_close.type: needFlipV ? PanelAnimation.DrawerFromBottom : PanelAnimation.DrawerFromTop

                width: root.menuWidth
                height: customSubmenuLoader.item ? customSubmenuLoader.item.implicitHeight : 32

                background: "transparent"

                x: {
                    if (!open || !level.activeItem)
                        return 8;

                    const p = level.activeItem.mapToItem(null, 0, 0);

                    const rightX = p.x + level.activeItem.width + 4;
                    const leftX = p.x - root.menuWidth - 4;
                    const maxX = customSubmenuPanel.screen.width - root.menuWidth - 8;

                    if (rightX <= maxX)
                        return rightX;

                    if (leftX >= 8)
                        return leftX;

                    return Math.max(8, Math.min(rightX, maxX));
                }

                y: {
                    if (!level.activeItem)
                        return 8;
                    const p = level.activeItem.mapToItem(null, 0, 0);
                    const maxY = customSubmenuPanel.screen.height - height - 8;

                    return Math.max(8, Math.min(p.y, maxY));
                }

                Loader {
                    id: customSubmenuLoader

                    anchors.fill: parent

                    active: customSubmenuPanel.open
                    sourceComponent: customMenuLevelComponent

                    property var menuItems: level.activeItem ? level.activeItem.modelData.children : []
                    property var rootMenu: level.rootMenu

                    onLoaded: {
                        if (item) {
                            item.menuItems = menuItems;
                            item.rootMenu = rootMenu;
                        }
                    }

                    onMenuItemsChanged: {
                        if (item)
                            item.menuItems = menuItems;
                    }
                }
            }
        }
    }

    // Native menu contents.
    Component {
        id: nativeMenuLevelComponent

        Item {
            id: level

            property var menuHandle: null
            property var rootMenu: null
            property Item activeItem: null

            readonly property int maxHeight: rootMenu ? rootMenu.maxMenuHeight : 350

            width: root.menuWidth
            implicitWidth: root.menuWidth

            implicitHeight: nativeFlickable.height + 12
            height: implicitHeight

            QsMenuOpener {
                id: opener
                menu: level.menuHandle
            }

            Rectangle {
                anchors.fill: parent

                color: Theme.background
                border.color: Theme.accent.alpha(0.25)
                border.width: 1

                Flickable {
                    id: nativeFlickable

                    anchors.centerIn: parent

                    width: root.itemWidth
                    height: Math.max(0, Math.min(nativeColumn.implicitHeight, level.maxHeight - 12))

                    contentWidth: width
                    contentHeight: nativeColumn.implicitHeight

                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: nativeColumn

                        width: nativeFlickable.width
                        spacing: 2

                        Repeater {
                            model: opener.children

                            delegate: Item {
                                id: nativeItem

                                required property var modelData

                                readonly property bool separator: !!(modelData && modelData.isSeparator)
                                readonly property bool hasSubmenu: !!(modelData && modelData.hasChildren)

                                width: root.itemWidth
                                height: separator ? 7 : root.itemHeight

                                Rectangle {
                                    visible: nativeItem.separator

                                    anchors.centerIn: parent
                                    width: 150
                                    height: 1
                                    color: Theme.text.alpha(0.1)
                                }

                                Rectangle {
                                    visible: !nativeItem.separator

                                    anchors.fill: parent
                                    radius: 8

                                    color: nativeItemMouse.containsMouse ? Theme.accent.alpha(0.18) : "transparent"

                                    Row {
                                        anchors.fill: parent

                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10

                                        spacing: 8

                                        Text {
                                            visible: modelData && modelData.buttonType !== 0

                                            width: 12
                                            anchors.verticalCenter: parent.verticalCenter

                                            text: modelData && modelData.checkState === Qt.Checked ? "✓" : modelData && modelData.checkState === Qt.PartiallyChecked ? "−" : ""

                                            color: Theme.text
                                            font.pixelSize: 12
                                        }

                                        Image {
                                            visible: modelData && modelData.icon !== ""

                                            width: 16
                                            height: 16

                                            anchors.verticalCenter: parent.verticalCenter

                                            source: modelData ? modelData.icon : ""
                                            sourceSize: Qt.size(16, 16)
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        Text {
                                            id: nativeLabel
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 54

                                            text: modelData?.text ?? ""

                                            color: modelData && !modelData.enabled ? Theme.text.alpha(0.4) : Theme.text

                                            font.family: Theme.font
                                            font.pixelSize: 12
                                            font.bold: true

                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: nativeItem.hasSubmenu

                                            anchors.verticalCenter: parent.verticalCenter

                                            text: "›"
                                            color: Theme.text
                                            font.pixelSize: 18
                                        }
                                    }

                                    MouseArea {
                                        id: nativeItemMouse

                                        anchors.fill: parent

                                        enabled: modelData && modelData.enabled && !nativeItem.separator

                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: {
                                            if (nativeItem.hasSubmenu) {
                                                level.activeItem = nativeItem;
                                            } else {
                                                level.activeItem = null;
                                            }
                                        }

                                        onClicked: {
                                            if (nativeItem.hasSubmenu)
                                                return;
                                            if (modelData && modelData.triggered)
                                                modelData.triggered();

                                            if (level.rootMenu)
                                                level.rootMenu.close();
                                        }
                                    }

                                    ToolTip {
                                        target: nativeItemMouse
                                        text: nativeLabel.truncated ? nativeLabel.text : ""
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: nativeFlickable.contentHeight > nativeFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

                        width: 6

                        background: Rectangle {
                            color: "transparent"
                        }

                        contentItem: Rectangle {
                            radius: 3
                            color: Theme.accent
                        }
                    }
                }
            }

            // Single shared native submenu panel for this level
            FloatingPanel {
                id: nativeSubmenuPanel

                open: level.rootMenu !== null && level.rootMenu.isOpen && level.activeItem !== null && level.activeItem.hasSubmenu

                touchOutside: false

                origin: FloatingPanel.TopLeft
                restrict: FloatingPanel.Flip

                on_open.type: needFlipV ? PanelAnimation.DrawerFromBottom : PanelAnimation.DrawerFromTop
                on_close.type: needFlipV ? PanelAnimation.DrawerFromBottom : PanelAnimation.DrawerFromTop

                width: root.menuWidth
                height: nativeSubmenuLoader.item ? nativeSubmenuLoader.item.implicitHeight : 32

                background: "transparent"

                x: {
                    if (!open || !level.activeItem)
                        return 8;

                    const p = level.activeItem.mapToItem(null, 0, 0);

                    const submenuWidth = root.menuWidth;
                    const rightX = p.x + level.activeItem.width + 4;
                    const leftX = p.x - submenuWidth - 4;
                    const maxX = nativeSubmenuPanel.screen.width - submenuWidth - 8;

                    if (rightX <= maxX)
                        return rightX;

                    if (leftX >= 8)
                        return leftX;

                    return Math.max(8, Math.min(rightX, maxX));
                }

                y: {
                    if (!level.activeItem)
                        return 8;
                    const p = level.activeItem.mapToItem(null, 0, 0);
                    const maxY = nativeSubmenuPanel.screen.height - height - 8;

                    return Math.max(8, Math.min(p.y, maxY));
                }

                Loader {
                    id: nativeSubmenuLoader

                    anchors.fill: parent

                    active: nativeSubmenuPanel.open
                    sourceComponent: nativeMenuLevelComponent

                    property var menuHandle: level.activeItem ? level.activeItem.modelData : null
                    property var rootMenu: level.rootMenu

                    onLoaded: {
                        if (item) {
                            item.menuHandle = menuHandle;
                            item.rootMenu = rootMenu;
                        }
                    }

                    onMenuHandleChanged: {
                        if (item)
                            item.menuHandle = menuHandle;
                    }
                }
            }
        }
    }

    function open(item, menuItems): void {
        nativeMenu = null;
        items = menuItems;
        target = item;
        isOpen = true;
    }

    function openNative(item, handle): void {
        items = [];
        nativeMenu = handle;
        target = item;
        isOpen = true;
    }

    function close(): void {
        isOpen = false;
        target = null;
        items = [];
        nativeMenu = null;
    }
}
