import QtQuick.Controls.Material
import QtQuick.Controls.Fusion
import QtQuick
import QShopper

Delegate {
    id: root

    property bool editor
    property bool canUndo

    signal addItem(string text)
    signal barsTapped()
    signal timeout()
    signal undo()

    function insert(text) {
        if (text === "") {
            return
        }
        input.clear()
        input.insert(0, text)
        input.forceActiveFocus()
    }

    contentItem: TextField {
        id: input

        function addItem() {
            Qt.inputMethod.commit()
            if (text === "") {
                return
            }
            root.addItem(input.text)
            clear()
            root.timeout()
        }

        background:  Rectangle { color: Material.backgroundColor; opacity: 0.8 }
        color: Material.primaryTextColor
        placeholderTextColor: Material.secondaryTextColor
        focus: true
        EnterKey.type: Qt.EnterKeyReturn
        font { pixelSize: Theme.pixels(3.5) }
        horizontalAlignment: Text.AlignHCenter
        leftPadding: height
        rightPadding: height
        placeholderText: qsTr("Tap to add items")

        onAccepted: addItem()
        onPressed: {
            forceActiveFocus()
            Qt.inputMethod.show()
        }

        // Voice {
        //     onAdd: {
        //         root.text = text
        //         Qt.inputMethod.commit()
        //         addItem()
        //     }
        //     onClear: root.clear()
        //     onRemove: mainView.deleteIndex = index - 1
        // }

        Flipable {
            id: switcher

            anchors { verticalCenter: parent.verticalCenter; left: parent.left }
            back: UndoIcon {
                anchors { fill: parent }
                font { family: root.font.family }
                enabled: root.canUndo
                opacity: 1.0
                onClicked: root.undo()
                onTimeout: root.timeout()
                z: 3
                Material.theme: Theme.theme
            }
            front: Icon {
                anchors { fill: parent }
                font { family: root.font.family }
                text: "\uf0c9"
                enabled: !root.canUndo
                opacity: 1.0
                onClicked: root.barsTapped()
                Material.theme: Theme.theme
            }
            height: parent.height; width: height
            states: State {
                name: "back"
                PropertyChanges { rotation.angle: -180 }
                when: root.canUndo
            }
            transform: Rotation {
                id: rotation
                origin.x: Math.round(switcher.width / 2)
                origin.y: Math.round(switcher.height / 2)
                axis.x: 0; axis.y: 1; axis.z: 0; angle: 0
            }
            transitions: Transition {
                DefaultAnimation { target: rotation; property: "angle"; duration: 500 }
            }
        }

        Icon {
            anchors { verticalCenter: parent.verticalCenter; right: parent.right }
            font { family: root.font.family }
            enabled: input.text || input.preeditText
            height: parent.height; width: height
            text: "\uf057"
            onClicked: {
                // Qt.inputMethod.commit()
                input.clear()
            }
            Material.theme: Theme.theme
        }
    }

    Keys.onReturnPressed: {
        // Qt.inputMethod.commit()
        input.addItem()
    }

    Keys.onEscapePressed: input.focus = false

    Material.theme: Theme.inverseTheme
}
