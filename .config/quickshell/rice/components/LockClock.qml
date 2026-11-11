import QtQuick
import Quickshell
import "../singletons/"

Text {
    color: Theme.text

    font.family: Theme.font
    font.pixelSize: 95
    font.bold: true
    property string format: "hh:mm:ss AP"
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, format)
}
