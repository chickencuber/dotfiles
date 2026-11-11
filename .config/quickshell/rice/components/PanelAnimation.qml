import QtQuick

QtObject {
    enum AnimationType {
        None,
        Left,
        Right,
        Top,
        Bottom,
        DrawerFromTop,
        DrawerFromBottom,
        DrawerFromLeft,
        DrawerFromRight,
        Fade
    }
    property int animationDuration: 200
    property int animationEasing: Easing.OutCubic
    property int type: PanelAnimation.None
}
