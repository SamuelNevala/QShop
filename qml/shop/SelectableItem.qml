import QtQuick 2.0

Delegate {
    dragThreshold: root.dragDistance
    dragEnabled: root.state === "edit"

    onSideChanged: {
        if (root.state === "edit")
            itemModel.remove(index)
        else
            itemModel.toggleSelected(index)
    }

    onDropAreaEntered: {
        root.skipMoveTransition = true
        itemModel.move(dragSource.itemIndex, index)
    }
}

