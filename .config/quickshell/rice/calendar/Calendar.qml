import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    visible: false

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property date displayedDate: new Date()

    function open(): void {
        displayedDate = new Date();
        root.visible = true;
    }

    function close(): void {
        root.visible = false;
    }

    function toggle(): void {
        if (root.visible)
            close();
        else
            open();
    }

    function previousMonth(): void {
        displayedDate = new Date(
            displayedDate.getFullYear(),
            displayedDate.getMonth() - 1,
            1
        );
    }

    function nextMonth(): void {
        displayedDate = new Date(
            displayedDate.getFullYear(),
            displayedDate.getMonth() + 1,
            1
        );
    }

    function daysInMonth(year, month): int {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfMonth(year, month): int {
        return new Date(year, month, 1).getDay();
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.close()
    }

    // Entire screen catches outside clicks
    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    // Actual calendar popup
    Rectangle {
        id: calendarPopup

        width: 400
        height: 440

        anchors {
            top: parent.top
            right: parent.right

            topMargin: 40
            rightMargin: 20
        }

        radius: 18

        color: Theme.background
        border.color: Theme.accent
        border.width: 1

        // Prevent clicks inside the calendar
        // from reaching the fullscreen MouseArea.
        MouseArea {
            anchors.fill: parent

            onClicked: mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16

            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true

                    text: Qt.formatDate(
                        root.displayedDate,
                        "MMMM yyyy"
                    )

                    color: Theme.foreground
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 20
                    font.bold: true
                }

                Rectangle {
                    width: 34
                    height: 34

                    radius: 8
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent

                        text: "‹"

                        color: Theme.foreground
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: root.previousMonth()
                    }
                }

                Rectangle {
                    width: 34
                    height: 34

                    radius: 8
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent

                        text: "›"

                        color: Theme.foreground
                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: root.nextMonth()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true

                columns: 7

                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: [
                        "Sun",
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat"
                    ]

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter

                        text: modelData

                        color: Theme.foreground
                        opacity: 0.6

                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 12
                    }
                }
            }

            GridLayout {
                id: calendarGrid

                Layout.fillWidth: true
                Layout.fillHeight: true

                columns: 7

                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: 42

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 8

                        property int index: modelData
                        property int year: root.displayedDate.getFullYear()
                        property int month: root.displayedDate.getMonth()
                        property int firstDay:
                            root.firstDayOfMonth(year, month)

                        property int day:
                            index - firstDay + 1

                        property bool validDay:
                            day >= 1 &&
                            day <= root.daysInMonth(year, month)

                        property bool today:
                            validDay &&
                            day === new Date().getDate() &&
                            month === new Date().getMonth() &&
                            year === new Date().getFullYear()

                        color: today
                            ? Theme.accent.alpha(0.18)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent

                            text: parent.validDay
                                ? parent.day
                                : ""

                            color: parent.today
                                ? Theme.accent
                                : Theme.foreground

                            font.family: "JetBrainsMono Nerd Font Mono"
                            font.pixelSize: 14
                            font.bold: parent.today
                        }
                    }
                }
            }
        }
    }
}
