pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../components/"
import "../singletons/"

Scope {
    id: root
    function closed() {
        field.text = "";
        command_history_index = -1;
    }

    function opened() {
        getHistory.running = true;
        field.forceActiveFocus();
    }
    function show_command_history() {
        if (command_history_index === -1) {
            field.text = "";
        } else if (command_history_index < -1) {
            command_history_index = -1;
        } else {
            field.text = command_history[command_history_index];
        }
    }

    property int command_history_index: -1
    property list<string> command_history: []
    Process {
        id: getHistory
        command: ["fish", "-c", "history"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.command_history = text.trim().split("\n");
            }
        }
    }
    Process {
        id: updateFishAutocomplete
        command: ["fish", "-c", "complete -C \"$argv[1]\"", field.text]
        stdout: StdioCollector {
            onStreamFinished: {
                if (field.text === "") {
                    commandSuggestion.text = "";
                    return;
                }
                let out = text.split("\n")[0].split("\t")[0];

                let len = field.text.length;

                let repeat = " ".repeat(len);

                let args = field.text.split(" ");

                let lastArg = args[args.length - 1];
                let lenl = lastArg.length;

                let regex = ".".repeat(lenl);

                if (out.startsWith(lastArg)) {
                    out = out.replace(new RegExp(regex), "");
                }

                out = repeat + out;

                commandSuggestion.text = out;
            }
        }
    }
    Process {
        id: updateHistory
        command: ["fish", "-c", "history append -- \"$argv[1]\"", field.text]
    }
    FloatingPanel {
        id: win
        ipc: "command"
        width: 800
        height: 50
        origin: FloatingPanel.Center
        on_open.type: PanelAnimation.Fade
        on_close.type: PanelAnimation.Fade
        background: "transparent"
        onAnimationFinished: {
            if (open) {
                root.opened();
            } else {
                root.closed();
            }
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.width: 2
            border.color: Theme.accent
            radius: 22
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12

                text: "⇝"
                color: Theme.text

                font.family: Theme.font
                font.pixelSize: 20
            }
            Text {
                id: commandSuggestion
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 26
                color: Theme.suggestion

                font.family: Theme.font
                font.pixelSize: 20

                z: 0
            }
            TextField {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                focus: true
                font.pixelSize: 20
                leftPadding: 10
                rightPadding: 10
                topPadding: 6
                bottomPadding: 6
                font.family: Theme.font
                Keys.onTabPressed: {
                    const a = field.text;
                    const b = commandSuggestion.text;
                    const result = a + b.substring(a.length);
                    field.text = result;
                }
                Keys.onEscapePressed: {
                    win.open=false
                }
                onAccepted: {
                    updateHistory.running = true;
                    Quickshell.execDetached(["fish", "-c", text]);
                    win.open = false;
                }
                Keys.onUpPressed: {
                    root.command_history_index++;
                    root.show_command_history();
                }

                Keys.onDownPressed: {
                    root.command_history_index--;
                    root.show_command_history();
                }
                onTextChanged: updateFishAutocomplete.running = true
                background: null
            }
        }
    }
}
