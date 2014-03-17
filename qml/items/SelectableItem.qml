import QtQuick 2.0

Swipeable {
    id: root

    dragThreshold: applicationWindow.dragDistance
    height: constants.maxHeight
    target: rect

    Flipable {
        id: rect
        anchors.fill: parent
        //anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        //height: constants.maxHeight
        transform: root.rotation
        //width: parent.width

        front: TextItem {
            anchors { fill: rect }
            text { text: itemText; color: "white" }
            Behavior on color { ColorAnimation { } }
        }

        back: TextItem {
            anchors.fill: rect
            text {
                text: itemText
                font.strikeout: true
                color: "darkgray"
            }
            Behavior on color { ColorAnimation { } }
        }
    }

    onSideChanged: itemModel.toggleSelected(index)

    Component.onCompleted: root.setStartSide(selected)
}


/*
Delegate {

    //dragEnabled: list.state === "edit"

    onSideChanged: {
      /*  if (list.state === "edit")
            itemModel.remove(index)
        else*//*
            itemModel.toggleSelected(index)
    }

   /* onDropAreaEntered: {
        root.skipMoveTransition = true
        itemModel.move(dragSource.itemIndex, index)
    }*//*

    //onDoubleClicked: if (list.state === "edit") itemModel.moveEditor(index)
}*/

