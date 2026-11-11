pragma Singleton
import QtQuick
import Quickshell
import "../singletons/"

Scope {
    id: root

    OSD {
        ipc: "osd.caps"

        icon: ShellContext.wm.caps ? "shift_lock" : "shift_lock_off"

        label: ShellContext.wm.caps ? "Caps On" : "Caps Off"

        showProgress: false
        showValue: false

        timeout: 1000

        function afterTriggered() {
            ShellContext.wm.updateKeys(() => {open()})

        }
    }
}
