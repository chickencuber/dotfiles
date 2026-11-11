pragma Singleton
import "../services/wms"

import Quickshell
import QtQuick

QtObject {
    property WM wm

    function iconPath(name: string, check: bool): string {
        if (name === "")
            return "";

        const themed = Quickshell.iconPath(name, true);

        if (themed !== "")
            return themed;

        return Quickshell.iconPath(Quickshell.env("HOME") + "/.local/share/icons/" + name + ".png", check);
    }
}
