import QtQuick 2.0
import QtQuick.Controls 1.0

Item {
    id: root

    property alias text: input.text
    property alias enabled: input.enabled

    signal accepted()
    signal dropAreaEntered(Item dragSource)

    height: 90
    opacity: enabled ? 1.0 : 0.0
    visible: opacity > 0.0

    Item {
        id: testme
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        height: dragSpot.pressed ? 90 * 1.3 : 90
        width: parent.width

        Drag.active: dragSpot.dragArea.drag.active
        Drag.source: dragSpot
        Drag.hotSpot.y: Math.round( height / 2 )
        Drag.hotSpot.x:  width - 50

        TextField {
            id: input
            anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter }
            font.pixelSize: 25
            focus: true
            horizontalAlignment: Text.AlignHCenter
            height: parent.height * 0.62
            onAccepted: root.accepted()
            opacity: 1
            z:1
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: "black"
            opacity: 0.8
        }

        DragSpot {
            id: dragSpot

            property int itemIndex: index

            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: height; target: parent
            dragEnabled: true
        }
    }

    DropArea {
        anchors { fill: parent }
        onEntered:  root.dropAreaEntered(drag.source)
        enabled: true
    }

    states: [
        State {
            name: "drag"; when: testme.Drag.active
            ParentChange { target: testme; parent: root.parent.parent.parent }
            PropertyChanges { target: testme; z: 1}
            AnchorChanges {
                target: testme;
                anchors.horizontalCenter: undefined;
                anchors.verticalCenter: undefined
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    ]

    transitions:  [
        Transition {
            from: "drag"
            ParentAnimation { }
            AnchorAnimation { }
        }
    ]

    Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
}
