import QtQuick
import Quickshell

BarButton {
    property string format: "hh:mm:ss AP"
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, format)
}
