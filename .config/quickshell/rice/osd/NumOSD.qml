pragma Singleton
import QtQuick
import Quickshell
import "../singletons/"
import "../components/"

Scope {
    id: root

    OSD {
        ipc: "osd.num"

        icon: ShellContext.wm.num ? "num-lock-on" : "num-lock-off"
        source: Icon.System

        label: ShellContext.wm.num ? "Num On" : "Num Off"

        showProgress: false
        showValue: false

        timeout: 1000

        function afterTriggered() {
            ShellContext.wm.updateKeys(() => {open()})

        }
    }
}
