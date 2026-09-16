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
    readonly property color suggestion: palette.placeholderText
    readonly property color textMuted:  text.alpha(0.65)
    readonly property color accentTextMuted: accentText.alpha(0.65)
}
