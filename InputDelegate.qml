import QtQuick
import QtQuick.Controls.Basic
import QDynamics
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
        if (text === "") return;
        input.clear();
        input.insert(0, text);
        input.forceActiveFocus();
    }

    contentItem: TextField {
        id: input

        function addItem() {
            if (text === "") return;
            root.addItem(input.text);
            clear();
            root.timeout();
        }

        background:  Rectangle { color: "white"; opacity: 0.8 }
        focus: true
        font { pixelSize: root.dimensions.mm(3.5) }
        horizontalAlignment: Text.AlignHCenter
        leftPadding: height
        rightPadding: height
        placeholderText: qsTr("Tap to insert items")

        onAccepted: addItem()

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
                dimensions: root.dimensions
                font { family: root.font.family }
                enabled: root.canUndo
                opacity: 1.0
                onClicked: root.undo()
                onTimeout: root.timeout()
                z: 3
            }
            front: Icon {
                anchors { fill: parent }
                dimensions: root.dimensions
                font { family: root.font.family }
                text: "\uf0c9"
                enabled: !root.canUndo
                opacity: 1.0
                onClicked: root.barsTapped();
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
            dimensions: root.dimensions
            font { family: root.font.family }
            enabled: input.text || input.preeditText
            height: parent.height; width: height
            text: "\uf057"
            onClicked: {
                // Qt.inputMethod.commit()
                input.clear()
            }
        }
    }

    Keys.onReturnPressed: {
        // Qt.inputMethod.commit()
        input.addItem();
    }

    Keys.onEscapePressed: input.focus = false;
}
