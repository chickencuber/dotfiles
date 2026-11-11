import QtQuick
import "../singletons/"

Module {
    id: mod
    Rectangle {
        implicitWidth: 1
        implicitHeight: mod.bar_thickness

        color: Theme.textMuted
        opacity: 0.35
    }
}
