import QtQuick 2.0

Delegate {
    dragThreshold: applicationWindow.dragDistance
    //dragEnabled: list.state === "edit"

    onSideChanged: {
      /*  if (list.state === "edit")
            itemModel.remove(index)
        else*/
            itemModel.toggleSelected(index)
    }

    onDropAreaEntered: {
        root.skipMoveTransition = true
        itemModel.move(dragSource.itemIndex, index)
    }

    //onDoubleClicked: if (list.state === "edit") itemModel.moveEditor(index)
}

