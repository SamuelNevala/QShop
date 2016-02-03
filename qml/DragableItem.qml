import QtQuick 2.4
import QtQuick.Controls 1.3

Swipeable {
    id: root

    function remove() {
        if (!remorse) {
            remorse = remorseComponent.createObject(root);
        }
        remorse.state = "remorse"
        resetX(0)
    }

    implicitHeight: theme.heights.large

    property RemorseItem remorse

    MouseArea {
        id: bottomMouseArea
        anchors { fill: parent }
        propagateComposedEvents: true
        onClicked: if (!checked) itemModel.moveEditor(index)
        onPressed: mouse.accepted = false
    }

    Item {
        id: backgound
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        height: theme.heights.large
        scale: dragSpot.pressed ? 1.15 : 1

        states: State {
            name: "drag"; when: backgound.Drag.active
            ParentChange { target: backgound; parent: mainView }
            PropertyChanges { target: backgound; z: 1 }
            AnchorChanges {
                target: backgound;
                anchors.horizontalCenter: undefined;
                anchors.verticalCenter: undefined
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
        transitions: Transition { from: "drag"; ParentAnimation { } AnchorAnimation { } }
        width: parent.width

        TextItem {
            anchors { fill: parent }
            padding: textWidth >= root.width ? dragSpot.width : 0
            opacity: remorse && remorse.state == "remorse" ? 0.0 : 1.0
            Behavior on opacity { DefaultAnimation { } }
        }

        IconButton {
            id: dragSpot
            property int itemIndex: index
            anchors { verticalCenter: parent.verticalCenter; right: parent.right }
            drag { target: backgound }
            enabled: !checked && !(remorse && remorse.state == "remorse")
            height: theme.heights.medium
            source: "qrc:/drag"
            width: height
        }

        Drag.active: dragSpot.drag.active
        Drag.hotSpot.y: Math.round(root.height / 2)
        Drag.hotSpot.x:  Math.round(root.width / 2)
        Drag.source: dragSpot

        Behavior on scale { DefaultAnimation { } }
    }

    onAction: {
        if (rightSide) {
            remove()
        } else {
            var tmpIndex = index;
            itemModel.toggleChecked(index)
            resetX(tmpIndex == index ? 0 : theme.time.medium)
        }
    }

    DropArea {
        anchors { fill: parent }
        enabled: !checked
        onEntered: itemModel.move(drag.source.itemIndex, index)
    }

    Component {
        id: remorseComponent
        RemorseItem {
            title: qsTr("Removing %1").arg(name)
            cancel: (function() { mainView.deleteIndex = -1 })
            done: (function() { itemModel.remove(index); mainView.deleteIndex = -1 })
        }
    }

    Connections {
        target: mainView
        onDeleteIndexChanged: if (mainView.deleteIndex === index) remove()
    }
}
