import QtQuick 2.0
import QtGraphicalEffects 1.0

Swipeable {
    id: root

    property alias dragEnabled: dragSpot.dragEnabled

    signal dropAreaEntered(Item dragSource)

    height: 90
    target: rect

    Component.onCompleted: root.setStartSide(selected)

    Flipable {
        id: rect

        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        height: dragSpot.pressed ? 90 * 1.3 : 90
        transform: root.rotation
        width: parent.width

        Drag.active: dragSpot.dragArea.drag.active
        Drag.hotSpot.y: Math.round( height / 2 )
        Drag.hotSpot.x:  width - 50
        Drag.source: dragSpot

        Behavior on height { NumberAnimation { easing.type: Easing.InOutQuad } }

        front: FlippingDelegate {
            anchors { fill: parent }
            flip: root.preventStealing
            text { text: itemText; color: "white" }
            color: "black"
            Behavior on color { ColorAnimation { } }

            DragSpot {
                id: dragSpot
                property int itemIndex: index
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                target: rect; width: height
            }
        }

        back: FlippingDelegate {
            anchors.fill: parent
            flip: true
            text {
                text: itemText
                font.strikeout: true
                color: "darkgray"
            }
            color: "black"
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        states: [
            State {
                name: "drag"; when: rect.Drag.active
                ParentChange { target: rect; parent: root.parent.parent.parent }
                PropertyChanges { target: rect; z: 1}
                AnchorChanges {
                    target: rect;
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
    }

    DropArea {
        anchors { fill: parent }
        onEntered: root.dropAreaEntered(drag.source)
        enabled: root.dragEnabled && !selected
    }
}


