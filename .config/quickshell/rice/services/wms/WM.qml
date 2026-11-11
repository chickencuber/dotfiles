import QtQuick
import Quickshell

Scope {
    property var focusedWindow: null
    property var focusedWorkspace: null
    property string name: ""
    property var workspaces: []
    property point cursorPosition: Qt.point(0, 0)
    property bool caps: false
    property bool num: false

    function switchWorkspace(id) {
    }
    function updateCursorPosition(callback = () => {}) {
        callback();
    }
    function updateKeys(callback = () => {}) {
        callback();
    }
    function focusWindow(address) {
    }
    enum ScreenshotMode {
        ActiveMonitor,
        ActiveWindow,
        Monitor,
        Window,
        Region
    }

    function screenshot(mode: int, directory: string): void {
    }
}
