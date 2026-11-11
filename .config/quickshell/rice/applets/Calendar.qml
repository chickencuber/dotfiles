pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../components/"
import "../singletons/"

Scope {
    id: root

    property alias visible: panel.open

    // =========================================================
    // CONFIGURATION
    // =========================================================

    property int popupWidth: 400
    property int popupHeight: 550
    property int marginTop: 0

    // =========================================================
    // CALENDAR STATE
    // =========================================================

    property date displayedDate: new Date()
    property date selectedDate: new Date()

    property var calendarEvents: ({})

    property string loadedFrom: ""
    property string loadedTo: ""

    property string requestedFrom: ""
    property string requestedTo: ""

    property string activeFrom: ""
    property string activeTo: ""

    property bool reloadPending: false

    // =========================================================
    // DATE HELPERS
    // =========================================================

    function dateKey(date) {
        var year = date.getFullYear();
        var month = String(date.getMonth() + 1).padStart(2, "0");
        var day = String(date.getDate()).padStart(2, "0");

        return `${year}-${month}-${day}`;
    }

    function sameDate(a, b) {
        return dateKey(a) === dateKey(b);
    }

    function firstVisibleDate() {
        var first = new Date(displayedDate.getFullYear(), displayedDate.getMonth(), 1);

        first.setDate(first.getDate() - first.getDay());
        return first;
    }

    function lastVisibleDate() {
        var last = firstVisibleDate();
        last.setDate(last.getDate() + 41);

        return last;
    }

    function changeMonth(offset) {
        displayedDate = new Date(displayedDate.getFullYear(), displayedDate.getMonth() + offset, 1);

        selectedDate = new Date(displayedDate);
        requestEvents();
    }

    function previousMonth() {
        changeMonth(-1);
    }

    function nextMonth() {
        changeMonth(1);
    }

    // =========================================================
    // EVENTS
    // =========================================================

    function eventsForDate(date) {
        return calendarEvents[dateKey(date)] || [];
    }

    function addEvent(events, key, event) {
        if (!events[key])
            events[key] = [];

        events[key].push(event);
    }

    function addEventToDates(events, event) {
        if (!event.start)
            return;
        var cleanEvent = {
            title: event.title || "Untitled event",
            allDay: !!event.allDay,
            start: event.start || "",
            end: event.end || "",
            location: event.location || "",
            calendar: event.calendar || ""
        };

        var startKey = event.start.substring(0, 10);

        // All-day events use an exclusive end date.
        if (cleanEvent.allDay && event.end) {
            var current = new Date(startKey + "T00:00:00");
            var end = new Date(event.end.substring(0, 10) + "T00:00:00");

            while (current < end) {
                addEvent(events, dateKey(current), cleanEvent);
                current.setDate(current.getDate() + 1);
            }

            return;
        }

        addEvent(events, startKey, cleanEvent);
    }

    function parseOmaCal(output) {
        try {
            var result = JSON.parse(output);

            if (!result.ok || !Array.isArray(result.data)) {
                console.log("OmaCal returned invalid data");
                return;
            }

            var events = {};

            for (var i = 0; i < result.data.length; i++)
                addEventToDates(events, result.data[i]);

            calendarEvents = events;
            loadedFrom = activeFrom;
            loadedTo = activeTo;
        } catch (error) {
            console.log("OmaCal JSON error:", error);
        }
    }

    function eventTime(event) {
        if (event.allDay)
            return "All day";

        if (!event.start)
            return "";

        var result = Qt.formatTime(new Date(event.start), "h:mm AP");

        if (event.end)
            result += " – " + Qt.formatTime(new Date(event.end), "h:mm AP");

        return result;
    }

    // =========================================================
    // OMACAL
    // =========================================================

    function requestEvents() {
        requestedFrom = dateKey(firstVisibleDate());
        requestedTo = dateKey(lastVisibleDate());

        if (requestedFrom === loadedFrom && requestedTo === loadedTo)
            return;
        if (omaCal.running) {
            reloadPending = true;
            return;
        }

        loadTimer.restart();
    }

    function startLoad() {
        if (omaCal.running) {
            reloadPending = true;
            return;
        }

        activeFrom = requestedFrom;
        activeTo = requestedTo;

        omaCal.running = true;
    }

    Process {
        id: omaCal

        command: ["fish", "-c", "$argv", "omacal", "events", "list", "--from", root.activeFrom, "--to", root.activeTo, "--json"]

        stdout: StdioCollector {
            onStreamFinished: root.parseOmaCal(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.log("OmaCal:", text.trim());
            }
        }

        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                console.log("OmaCal exited:", exitCode);

            if (root.reloadPending) {
                root.reloadPending = false;
                root.requestEvents();
            }
        }
    }

    Timer {
        id: loadTimer

        interval: 120
        repeat: false

        onTriggered: root.startLoad()
    }

    // =========================================================
    // FLOATING PANEL
    // =========================================================

    FloatingPanel {
        id: panel

        ipc: "calendar"

        width: root.popupWidth
        height: root.popupHeight

        origin: FloatingPanel.Mouse
        restrict: FloatingPanel.Flip

        x: 10
        y: 10

        marginTop: root.marginTop

        background: "transparent"

        on_open.type: PanelAnimation.DrawerFromTop
        on_close.type: PanelAnimation.DrawerFromTop

        onOpenChanged: {
            if (open) {
                var today = new Date();

                root.displayedDate = today;
                root.selectedDate = today;

                root.requestEvents();
            }
        }

        Rectangle {
            anchors.fill: parent

            radius: 14
            color: Theme.background

            border.width: 1
            border.color: Theme.accent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // =================================================
                // HEADER
                // =================================================

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    Text {
                        Layout.fillWidth: true

                        text: Qt.formatDate(root.displayedDate, "MMMM yyyy")

                        color: Theme.foreground

                        font.family: Theme.font
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            {
                                icon: "chevron_left",
                                action: -1
                            },
                            {
                                icon: "chevron_right",
                                action: 1
                            }
                        ]

                        Rectangle {
                            required property var modelData

                            width: 28
                            height: 28
                            radius: 7
                            color: "transparent"

                            Icon {
                                anchors.centerIn: parent

                                name: modelData.icon
                                iconColor: Theme.foreground

                                width: 22
                                height: width
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: root.changeMonth(modelData.action)
                            }
                        }
                    }
                }

                // =================================================
                // WEEKDAYS
                // =================================================

                GridLayout {
                    Layout.fillWidth: true

                    columns: 7
                    columnSpacing: 3

                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                        Text {
                            required property string modelData

                            Layout.fillWidth: true

                            text: modelData
                            horizontalAlignment: Text.AlignHCenter

                            color: Theme.foreground
                            opacity: 0.5

                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                    }
                }

                // =================================================
                // CALENDAR GRID
                // =================================================

                GridLayout {

                    Layout.fillWidth: true
                    Layout.preferredHeight: 252
                    Layout.minimumHeight: 252
                    Layout.maximumHeight: 252

                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: 42

                        Rectangle {
                            id: day

                            required property int index

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            radius: 8

                            property date cellDate: {
                                var date = root.firstVisibleDate();
                                date.setDate(date.getDate() + index);
                                return date;
                            }

                            property bool currentMonth: cellDate.getMonth() === root.displayedDate.getMonth()

                            property bool selected: root.sameDate(cellDate, root.selectedDate)

                            property bool today: root.sameDate(cellDate, new Date())

                            property int eventCount: root.eventsForDate(cellDate).length

                            color: selected ? Theme.surface : "transparent"

                            border.width: selected ? 1 : 0
                            border.color: Theme.accent

                            Text {
                                anchors.centerIn: parent

                                text: day.cellDate.getDate()

                                color: Theme.foreground
                                opacity: day.currentMonth ? 1 : 0.3

                                font.family: Theme.font
                                font.pixelSize: 13
                                font.bold: day.selected || day.today
                            }

                            Rectangle {
                                visible: day.eventCount > 0

                                width: 5
                                height: 5
                                radius: 2.5

                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5

                                color: Theme.accent
                            }

                            Rectangle {
                                visible: day.today && !day.selected

                                width: 4
                                height: 4
                                radius: 2

                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 4

                                color: Theme.accent
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    root.selectedDate = new Date(day.cellDate);
                                }
                            }
                        }
                    }
                }

                // =================================================
                // SELECTED DAY
                // =================================================

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 125

                    radius: 10
                    color: Theme.surface

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        Text {
                            Layout.fillWidth: true

                            text: Qt.formatDate(root.selectedDate, "dddd, MMMM d, yyyy")

                            color: Theme.foreground

                            font.family: Theme.font
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1

                            color: Theme.background
                        }

                        Text {
                            visible: root.eventsForDate(root.selectedDate).length === 0

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            text: "No events"

                            verticalAlignment: Text.AlignVCenter

                            color: Theme.foreground
                            opacity: 0.5

                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                        ListView {
                            visible: root.eventsForDate(root.selectedDate).length > 0

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            clip: true
                            spacing: 6

                            model: root.eventsForDate(root.selectedDate)

                            delegate: ColumnLayout {
                                id: eventDelegate

                                required property string title
                                required property string calendar
                                required property string start
                                required property string end
                                required property string location
                                required property bool allDay

                                width: ListView.view.width
                                spacing: 1

                                property bool isHoliday: calendar.includes("Holidays")

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Text {
                                        Layout.fillWidth: true

                                        text: eventDelegate.title

                                        color: Theme.foreground

                                        font.family: Theme.font
                                        font.pixelSize: 11
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: eventDelegate.isHoliday

                                        text: "HOLIDAY"

                                        color: Theme.accent

                                        font.family: Theme.font
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: {
                                        var info = [];

                                        var time = root.eventTime({
                                            allDay: eventDelegate.allDay,
                                            start: eventDelegate.start,
                                            end: eventDelegate.end
                                        });

                                        if (time !== "")
                                            info.push(time);

                                        if (eventDelegate.location !== "")
                                            info.push(eventDelegate.location);

                                        if (eventDelegate.calendar !== "")
                                            info.push(eventDelegate.calendar);

                                        return info.join("  •  ");
                                    }

                                    color: Theme.foreground
                                    opacity: 0.5

                                    font.family: Theme.font
                                    font.pixelSize: 9

                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
