import QtQuick 2.4
import QtQuick.Controls 1.3

Swipeable {
    id: root

    implicitHeight: theme.heights.large

    property RemorseItem remorse

    MouseArea {
        id: bottomMouseArea
        anchors.fill: parent
        onClicked: if (!selected) itemModel.moveEditor(index)
        propagateComposedEvents: true
        onPressed: mouse.accepted = false
    }

    Item {
        id: backgound
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        height: theme.heights.large
        scale: dragSpot.pressed ? 1.15 : 1
        width: parent.width

        TextItem {
            id: text
            anchors.centerIn: parent
            height: parent.height
            width: parent.width
            opacity: remorse && remorse.state == "remorse" ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
        }

        states: [
            State {
                name: "drag"; when: backgound.Drag.active
                ParentChange { target: backgound; parent: root.parent.parent }
                PropertyChanges { target: backgound; z: 1 }
                AnchorChanges {
                    target: backgound;
                    anchors.horizontalCenter: undefined;
                    anchors.verticalCenter: undefined
                    anchors.left: parent.left
                    anchors.right: parent.right
                }
            }
        ]

        transitions:  [ Transition { from: "drag"; ParentAnimation {} AnchorAnimation {} }]

        Drag.active: dragSpot.drag.active
        Drag.hotSpot.y: Math.round( root.height / 2 )
        Drag.hotSpot.x:  Math.round( root.width / 2 )
        Drag.source: dragSpot

        IconButton {
            id: dragSpot
            property int itemIndex: index
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: -theme.heights.medium / 5 }
            drag { target: backgound }
            enabled: !selected && !(remorse && remorse.state == "remorse")
            height: theme.heights.medium
            source: "qrc:/drag"
            width: height
        }

        Behavior on scale { NumberAnimation { easing.type: Easing.InOutQuad } }
    }

    onAction: {
        if (rightSide) {
            if (!remorse) {
                remorse = remorseComponent.createObject(root);
            }
            remorse.state = "remorse"
            resetX(0)
        } else {
            var tmpIndex = index;
            itemModel.toggleSelected(index)
            resetX(tmpIndex == index ? 0 : constants.mediumTime )
        }
    }

    DropArea {
        anchors { fill: parent }
        enabled: !selected

        onEntered: itemModel.move(drag.source.itemIndex, index)
    }

    Component {
        id: remorseComponent

        RemorseItem {
            id: remorse
            height: parent.height
            opacity: 0.0
            title: qsTr("Removing %1").arg(itemText)
            label: qsTr("Tap to cancel")
            maximumValue: 6
            visible: opacity > 0.0
            width: parent.width
            x: parent.width

            states: State {
                name: "remorse"
                PropertyChanges { target: remorse; opacity: 0.8; x: 0 }
            }

            transitions: [
                Transition {
                    to: "remorse"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 500 }
                            NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: 500 }
                        }
                        ScriptAction { script: remorse.value = 0 }
                    }
                },
                Transition {
                    from: "remorse"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 500 }
                            NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: 500 }
                        }
                        ScriptAction { script: remorse.reset() }
                    }
                }
            ]
            onCancelled: remorse.state = ""
            onDone: itemModel.remove(index)
        }
    }
}
