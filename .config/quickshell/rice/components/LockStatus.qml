import QtQuick
import "../singletons/"

Text {
    required property LockScreen lockScreen;

    text: lockScreen.authenticating ? "Authenticating..." : lockScreen.message || "Input Password..."

    color: lockScreen.messageIsError ? Theme.accent : Theme.textMuted

    font.family: Theme.font
    font.pixelSize: 12
}
