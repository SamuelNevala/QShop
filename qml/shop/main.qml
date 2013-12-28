import QtQuick 2.0
import QtGraphicalEffects 1.0
import Shop.models 1.0

Image {
    id: root

    property int dragDistance

    height: 960; width: 540
    source: "qrc:/pic/bg"

    ListView {
        id: list

        anchors.fill: parent
        cacheBuffer: root.height * 3

        Pulley {
            id: pulley
            pullHint: root.state == "" ? "Pull to edit" : "Pull to shop"
            actionText: root.state == "" ? "Edit" : "Shop"
            onAction: root.state = root.state == "" ? "edit" : ""
        }

        header: Header {
            anchors { right: parent.right; left: parent.left }
            height: 70
        }

        model: ItemModel { id: itemModel }
        delegate: Swipeable {
            id: swipe
            anchors { right: parent.right; left: parent.left }
            height: 90
            target: rect
            dragThreshold: root.dragDistance

            property int indexx: index

            property bool testselection: selected
            onTestselectionChanged: {

                console.log("selected", selected)
                if (rect.Drag.active) swipe.setStartSide(selected)
            }


            Component.onCompleted: swipe.setStartSide(selected)

            onSideChanged: {
                if (root.state == "edit")
                    itemModel.remove(index)
                else
                    itemModel.toggleSelected(index)
                input.updateItemUnder()
            }

            Flipable {
                id: rect
                property bool remove: root.state == "edit" && swipe.finished
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                height: 90; width: parent.width
                transform: swipe.rotation

                Drag.active: dragSpot.dragArea.drag.active
                Drag.source: dragSpot
                Drag.hotSpot.y: Math.round( height / 2 )
                Drag.hotSpot.x:  width - 50

                DragSpot {
                    id: dragSpot
                    property int indexx: index
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        //margins: 10
                    }
                    width: height
                    target: rect
                    dragEnabled: root.state == "edit"
                }

                front: Delegate {
                    anchors { fill: parent }
                    flip: swipe.preventStealing
                    //rightMargin: root.state == "edit" ? dragSpot.width : 0
                    text { text: item; color: "white" }
                    color: rect.remove ||  rect.Drag.active ? "darkred" : "black"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                back: Delegate {
                    anchors.fill: parent
                    flip: true
                    //rightMargin: root.state == "edit" ? dragSpot.width  : 0
                    text {
                        text: item
                        font.strikeout: true
                        color: "darkgray"
                    }
                    color: rect.remove ||  rect.Drag.active ? "darkred" : "black"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                states: [
                    State {
                        name: "drag"; when: rect.Drag.active
                        ParentChange { target: rect; parent: root }
                        AnchorChanges {
                            target: rect;
                            anchors.horizontalCenter: undefined;
                            anchors.verticalCenter: undefined
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
                onEntered: itemModel.move(drag.source.indexx, swipe.indexx)
                //Rectangle { anchors.fill: parent; color: "yellow" }
                enabled: root.state == "edit"

            }
        }

        add: Transition {
            NumberAnimation { properties: "x, y"; easing.type: Easing.InOutQuad; duration: 500 }
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 400 }
            NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: 400 }
        }
        displaced: Transition {
            PropertyAction { property: "z"; value: 1 }
            NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: 400 }
            NumberAnimation { property: "opacity"; to: 1.0; duration: 400 }
            NumberAnimation { property: "scale"; to: 1.0; duration: 400 }
        }
        move: Transition {
            PropertyAction { property: "z"; value: -1 }
            NumberAnimation { properties: "x, y"; easing.type: Easing.InOutQuad; duration: 1000 }
        }
        /*populate: Transition {
            id: transition
            SequentialAnimation {
                 NumberAnimation { properties: "opacity"; easing.type: Easing.InOutQuad; to: 0.0; duration:0 }
                PauseAnimation { duration: (transition.ViewTransition.index - transition.ViewTransition.targetIndexes[0]) * 200 }
                ParallelAnimation{
                    NumberAnimation { properties: "opacity"; easing.type: Easing.InOutQuad; from: 0.0; to: 1.0 }
                    NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: 500 }
                }
            }
        }*/
        remove: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 400 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.0; duration: 400 } }

        onContentYChanged: input.updateItemUnder()
        onCountChanged:  {
            if (list.count == 0) root.state = "edit"
            input.updateItemUnder()
        }
        onContentHeightChanged: input.updateItemUnder()
        Component.onCompleted: if (list.count == 0) root.state = "edit"
    }

    InsertPosition {
        id: insert
        anchors { left: parent.left; right: parent.right; }
        enabled: input.enabled
        y:  input.itemUnder ? input.itemUnder.y + (input.atBottom ? itemUnder.height : 0) - height / 2 - list.contentY : input.y
    }

    Input {
        id: input

        function updateItemUnder() {
            if (!enabled) return
            itemUnder = list.itemAt(x, y + height / 2 + list.contentY)
        }

        anchors { left: parent.left; right: parent.right }
        displacement: list.contentY
        enabled: root.state == "edit" && !pulley.active
        maxDrag: Math.min(list.contentHeight, root.height) - input.height
        onAccepted: {
            var index = itemUnder ? itemUnder.indexx + (atBottom ? 1 : 0) : 0
            itemModel.insert(index, input.text)
            input.text = ""
        }
        onMaxDragChanged: {console.log(y, Math.abs(maxDrag)); y = Math.min(y, Math.abs(maxDrag))}
        onYChanged: updateItemUnder()
        Behavior on y { NumberAnimation {} }
    }

    states: [
        State { name: "edit" }
    ]
}



