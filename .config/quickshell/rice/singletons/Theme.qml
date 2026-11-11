pragma Singleton

import QtQuick

QtObject {
    readonly property SystemPalette palette: SystemPalette {}

    readonly property color background: palette.window
    readonly property color foreground: palette.windowText

    readonly property color surface: palette.base
    readonly property color text: palette.text

    readonly property color button: palette.button
    readonly property color buttonText: palette.buttonText

    readonly property color accent: palette.highlight
    readonly property color accentText: palette.highlightedText
    readonly property color suggestion: textMuted
    readonly property color textMuted:  text.alpha(0.65)
    readonly property color accentTextMuted: accentText.alpha(0.65)

    readonly property color dark: palette.dark

    readonly property string font: "JetBrainsMono Nerd Font Mono"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property string emojiFont: "Noto Color Emoji"
}
