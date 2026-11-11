import QtQuick
import "../singletons/"
Rectangle {
    id: root
    required property LockScreen lockScreen;
    width: 250
    height: 60

    radius: 10
    color: Theme.surface.alpha(0.5)

    border.width: 2
    border.color: Theme.accent

    TextInput {
        id: passwordField

        anchors.fill: parent
        anchors.margins: 8

        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter

        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText

        font.family: Theme.font
        font.pixelSize: 18
        font.letterSpacing: 1.5

        echoMode: TextInput.Password
        passwordCharacter: "●"

        enabled: !root.lockScreen.authenticating

        onTextEdited: root.lockScreen.password = text
        onAccepted: root.lockScreen.authenticate()

        Component.onCompleted: forceActiveFocus()

        Connections {
            target: root.lockScreen

            function onPasswordChanged() {
                if (passwordField.text !== root.lockScreen.password)
                    passwordField.text = root.lockScreen.password;
            }
        }
    }
}
