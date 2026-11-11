import QtQuick
import Quickshell
import "./services/wms"
import "./singletons/"
import "./osd/"
import "./applets/"
import "./panels/"

Scope {
    id: root
    property WM wm: Hyprland
    default property alias data: content.data
    readonly property var things_to_force_load_because_qml_is_stupid: [
        //osd
        BrightnessOSD,
        VolumeOSD,
        MediaOSD,
        CapsOSD,
        NumOSD,
        //applets
        CommandRunner,
        AppLauncher,
        FocusSwitcher,
        NotificationCenter,
        EmojiPicker,
        Calendar,
        PowerMenu,
        ClipboardManager,
        ScreenshotPicker,
        WallpaperPicker,
        //panels
        NotificationPopups,
        //singletons
        WallpaperRenderer
    ]
    Item {
        id: content
    }
    Binding {
        target: ShellContext
        property: "wm"
        value: root.wm
    }
}
