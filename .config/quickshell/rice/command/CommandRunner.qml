import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import ".."

Scope {
    id: scope

    Process {
        id: commandProcess
        stdout: StdioCollector {
            id: commandOutput
        }
    }
    function reset_command_window() {
        commandWindow.visible = false;
        commandInput.text = "";
        commandSuggestion.text = "";
        command_history_index = -1;
    }
    function run_command(command: list<string>, callback = () => {}): void {
        commandProcess.command = command;
        commandProcess.running = true;

        const handler = function () {
            callback(commandOutput.text.trim());
            commandProcess.exited.disconnect(handler);
        };
        commandProcess.exited.connect(handler);
    }

    function process_completion(output: string, input: string): void {
        let out = output.split("\n")[0].split("\t")[0];

        let len = input.length;

        let repeat = " ".repeat(len);

        let args = input.split(" ");

        let lastArg = args[args.length - 1];
        let lenl = lastArg.length;

        let regex = ".".repeat(lenl);

        if (out.startsWith(lastArg)) {
            out = out.replace(new RegExp(regex), "");
        }

        out = repeat + out;

        commandSuggestion.text = out;
    }
    property int command_history_index: -1
    property string font: "JetBrainsMono Nerd Font Mono"
    property list<string> command_history: []
    function show_command_history() {
        if (command_history_index === -1) {
            commandInput.text = "";
        } else if (command_history_index < -1) {
            command_history_index = -1;
        } else {
            commandInput.text = command_history[command_history_index];
        }
    }
    PanelWindow {
        id: commandWindow
        color: "transparent"
        focusable: true
        visible: false

        exclusionMode: ExclusionMode.Ignore

        IpcHandler {
            target: "command"
            function toggle(): void {
                commandWindow.visible = !commandWindow.visible;
                if (commandWindow.visible) {
                    scope.run_command(["fish", "-c", "history"], text => {
                        scope.command_history = text.trim().split("\n");
                    });
                } else {
                    scope.reset_command_window();
                }
            }
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        MouseArea {
            anchors.fill: parent

            onClicked: {
                scope.reset_command_window();
            }
        }

        Item {
            anchors.centerIn: parent

            width: 800
            height: 50

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

                    font.family: scope.font
                    font.pixelSize: 20
                }

                Text {
                    id: commandSuggestion
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 26

                    color: Theme.suggestion

                    font.family: scope.font
                    font.pixelSize: 20

                    z: 0
                }
                TextField {
                    id: commandInput

                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4

                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    font.family: scope.font
                    font.pixelSize: 20

                    leftPadding: 10
                    rightPadding: 10
                    topPadding: 6
                    bottomPadding: 6

                    onTextChanged: {
                        if (text.trim() === "") {
                            commandSuggestion.text = "";
                            return;
                        }
                        scope.run_command(["fish", "-c", "complete -C \"$argv[1]\"", text], text => {
                            scope.process_completion(text, commandInput.text);
                        });
                    }
                    onAccepted: {
                        scope.run_command(["fish", "-c", "history append -- \"$argv[1]\"", text]);
                        Quickshell.execDetached(["fish", "-c", text]);
                        scope.reset_command_window();
                    }

                    Keys.onEscapePressed: {
                        scope.reset_command_window();
                    }

                    Keys.onTabPressed: {
                        const a = commandInput.text;
                        const b = commandSuggestion.text;
                        const result = a + b.substring(a.length);
                        commandInput.text = result;
                    }
                    Keys.onUpPressed: {
                        scope.command_history_index++;
                        scope.show_command_history();
                    }

                    Keys.onDownPressed: {
                        scope.command_history_index--;
                        scope.show_command_history();
                    }

                    background: null
                }
            }
        }
    }
}
