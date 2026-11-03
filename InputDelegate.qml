import QShopper
import QtQuick
import QtQuick.Controls.Fusion as Fusion
import QtQuick.Controls.Material

Delegate {
    id: root

    property bool canUndo

    signal addItem(string text)
    signal barsTapped
    signal timeout
    signal undo

    function insert(text) {
        if (text === "") {
            return;
        }
        input.clear();
        input.insert(0, text);
        input.forceActiveFocus();
    }

    Material.theme: Theme.inverseTheme

    contentItem: Fusion.TextField {
        id: input

        function addItem() {
            Qt.inputMethod.commit();
            if (text === "") {
                return;
            }
            root.addItem(input.text);
            clear();
            root.timeout();
        }

        color: Material.primaryTextColor
        placeholderTextColor: Material.secondaryTextColor
        focus: true
        EnterKey.type: Qt.EnterKeyReturn
        horizontalAlignment: Text.AlignHCenter
        leftPadding: height
        rightPadding: height
        placeholderText: qsTr("Tap to add items")

        background: Rectangle {
            color: Material.backgroundColor
            opacity: 0.8
        }

        onAccepted: addItem()
        onPressed: {
            forceActiveFocus();
            Qt.inputMethod.show();
        }

        font {
            pixelSize: Theme.pixels(3.5)
        }

        Flipable {
            id: switcher

            height: parent.height
            width: height

            back: UndoIcon {
                enabled: root.canUndo
                opacity: 1.0
                z: 3
                Material.theme: Theme.theme

                onClicked: root.undo()
                onTimeout: root.timeout()

                anchors {
                    fill: parent
                }

                font {
                    family: root.font.family
                }
            }
            front: Icon {
                text: "\uf0c9"
                enabled: !root.canUndo
                opacity: 1.0
                Material.theme: Theme.theme

                onClicked: root.barsTapped()

                anchors {
                    fill: parent
                }

                font {
                    family: root.font.family
                }
            }
            states: State {
                name: "back"
                when: root.canUndo

                PropertyChanges {
                    rotation.angle: -180
                }
            }
            transform: Rotation {
                id: rotation

                origin.x: Math.round(switcher.width / 2)
                origin.y: Math.round(switcher.height / 2)
                axis.x: 0
                axis.y: 1
                axis.z: 0
                angle: 0
            }
            transitions: Transition {
                DefaultAnimation {
                    target: rotation
                    property: "angle"
                    duration: 500
                }
            }

            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
        }

        Icon {
            enabled: input.text || input.preeditText
            height: parent.height
            width: height
            text: "\uf057"
            Material.theme: Theme.theme

            onClicked: {
                // Qt.inputMethod.commit()
                input.clear();
            }

            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }

            font {
                family: root.font.family
            }
        }
    }

    Keys.onReturnPressed: {
        // Qt.inputMethod.commit()
        input.addItem();
    }
    Keys.onEscapePressed: input.focus = false
}
