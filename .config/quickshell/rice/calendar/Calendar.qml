import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    visible: false

    // =========================================================
    // FULLSCREEN WINDOW
    // =========================================================

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusiveZone: -1

    // =========================================================
    // POPUP POSITION
    // =========================================================

    property int cursorX: 0
    property int cursorY: 0

    property int popupWidth: 400
    property int popupHeight: 550

    property int popupMargin: 12

    property int popupX: {
        var x = cursorX + popupMargin;

        if (x + popupWidth > width)
            x = cursorX - popupWidth - popupMargin;

        return Math.max(8, Math.min(x, width - popupWidth - 8));
    }

    property int popupY: {
        var y = cursorY + popupMargin;

        if (y + popupHeight > height)
            y = cursorY - popupHeight - popupMargin;

        return Math.max(8, Math.min(y, height - popupHeight - 8));
    }

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
    // CURSOR POSITION
    // =========================================================

    Process {
        id: cursorProcess

        command: ["hyprctl", "cursorpos"]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim();

                var parts = value.split(",");

                if (parts.length >= 2) {
                    root.cursorX = parseInt(parts[0].trim());

                    root.cursorY = parseInt(parts[1].trim());
                }

                root.visible = true;
                root.requestEvents();
            }
        }
    }

    // =========================================================
    // DATE HELPERS
    // =========================================================

    function dateKey(date) {
        var year = date.getFullYear();
        var month = String(date.getMonth() + 1).padStart(2, "0");

        var day = String(date.getDate()).padStart(2, "0");

        return year + "-" + month + "-" + day;
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

    function previousMonth() {
        displayedDate = new Date(displayedDate.getFullYear(), displayedDate.getMonth() - 1, 1);
        selectedDate = new Date(displayedDate);
        requestEvents();
    }
    function nextMonth() {
        displayedDate = new Date(displayedDate.getFullYear(), displayedDate.getMonth() + 1, 1);
        selectedDate = new Date(displayedDate);
        requestEvents();
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

        // -----------------------------------------------------
        // ALL-DAY EVENTS
        // -----------------------------------------------------

        if (cleanEvent.allDay && event.end) {
            var current = new Date(startKey + "T00:00:00");

            var end = new Date(event.end.substring(0, 10) + "T00:00:00");

            while (current < end) {
                addEvent(events, dateKey(current), cleanEvent);

                current.setDate(current.getDate() + 1);
            }

            return;
        }

        // -----------------------------------------------------
        // NORMAL EVENT
        // -----------------------------------------------------

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

            for (var i = 0; i < result.data.length; i++) {
                addEventToDates(events, result.data[i]);
            }

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

        var start = new Date(event.start);

        var result = Qt.formatTime(start, "h:mm AP");

        if (event.end) {
            var end = new Date(event.end);

            result += " – " + Qt.formatTime(end, "h:mm AP");
        }

        return result;
    }

    // =========================================================
    // OMACAL LOADING
    // =========================================================

    function requestEvents() {
        requestedFrom = dateKey(firstVisibleDate());

        requestedTo = dateKey(lastVisibleDate());

        if (requestedFrom === loadedFrom && requestedTo === loadedTo) {
            return;
        }

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

        command: ["fish", "-c", "$argv","omacal", "events", "list", "--from", root.requestedFrom, "--to", root.requestedTo, "--json"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseOmaCal(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.log("OmaCal:", text.trim());
                }
            }
        }

        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0) {
                console.log("OmaCal exited:", exitCode);
            }

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

        onTriggered: {
            root.startLoad();
        }
    }

    // =========================================================
    // OPEN / CLOSE
    // =========================================================

    function open() {
        var today = new Date();

        displayedDate = today;
        selectedDate = today;

        // Get cursor position first.
        cursorProcess.running = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        if (visible)
            close();
        else
            open();
    }

    // =========================================================
    // ESCAPE
    // =========================================================

    FocusScope {
        anchors.fill: parent

        focus: true
        Keys.onEscapePressed: {
            root.close();
        }
    }

    // =========================================================
    // CLICK OUTSIDE
    // =========================================================

    MouseArea {
        anchors.fill: parent

        onClicked: {
            root.close();
        }
    }

    // =========================================================
    // ACTUAL CALENDAR POPUP
    // =========================================================

    Rectangle {
        id: popup

        x: root.popupX
        y: root.popupY

        width: root.popupWidth
        height: root.popupHeight

        radius: 14

        color: Theme.background

        border.width: 1
        border.color: Theme.accent

        // Prevent the fullscreen MouseArea
        // from closing the popup.
        MouseArea {
            anchors.fill: parent

            onClicked: {
                mouse.accepted = true;
            }
        }

        // =====================================================
        // CONTENT
        // =====================================================

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

                    font.family: "JetBrainsMono Nerd Font Mono"

                    font.pixelSize: 18
                    font.bold: true
                }

                Rectangle {
                    width: 28
                    height: 28

                    radius: 7

                    color: "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "‹"

                        color: Theme.foreground

                        font.family: "JetBrainsMono Nerd Font Mono"

                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            root.previousMonth();
                        }
                    }
                }

                Rectangle {
                    width: 28
                    height: 28

                    radius: 7

                    color: "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "›"

                        color: Theme.foreground

                        font.family: "JetBrainsMono Nerd Font Mono"

                        font.pixelSize: 24
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            root.nextMonth();
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
                        Layout.fillWidth: true

                        text: modelData

                        horizontalAlignment: Text.AlignHCenter

                        color: Theme.foreground

                        opacity: 0.5

                        font.family: "JetBrainsMono Nerd Font Mono"

                        font.pixelSize: 11
                    }
                }
            }

            // =================================================
            // CALENDAR GRID
            // =================================================

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

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

                            font.family: "JetBrainsMono Nerd Font Mono"

                            font.pixelSize: 13

                            font.bold: day.selected || day.today
                        }

                        // Event
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

                        // Today
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

                                mouse.accepted = true;
                            }
                        }
                    }
                }
            }

            // =================================================
            // SELECTED DAY INFO
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

                        font.family: "JetBrainsMono Nerd Font Mono"

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

                        font.family: "JetBrainsMono Nerd Font Mono"

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
                            width: ListView.view.width

                            spacing: 1

                            Text {
                                Layout.fillWidth: true

                                text: modelData.title

                                color: Theme.foreground

                                font.family: "JetBrainsMono Nerd Font Mono"

                                font.pixelSize: 11

                                font.bold: true

                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true

                                text: {
                                    var info = [];

                                    var time = root.eventTime(modelData);

                                    if (time !== "")
                                        info.push(time);

                                    if (modelData.location !== "") {
                                        info.push(modelData.location);
                                    }

                                    if (modelData.calendar !== "") {
                                        info.push(modelData.calendar);
                                    }

                                    return info.join("  •  ");
                                }

                                color: Theme.foreground

                                opacity: 0.5

                                font.family: "JetBrainsMono Nerd Font Mono"

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
