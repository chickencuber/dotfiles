import QtQuick

Item {
    id: root

    enum Side {
        Left,
        Right,
        Top,
        Bottom
    }

    property var bar
    readonly property int bar_thickness: bar.thickness
    property int bar_side

    readonly property bool horizontal:
        bar_side == Module.Left || bar_side == Module.Right
    readonly property bool vertical: !horizontal

    default property alias children: content.data
    implicitHeight: content.childrenRect.height
    implicitWidth: content.childrenRect.width

    Item {
        id: content
    }
}
