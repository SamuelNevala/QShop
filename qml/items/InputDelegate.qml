import QtQuick 2.0

Input {
    id: input

    onAccepted: {
        itemModel.insert(index, input.text)
        input.text = ""
        list.positionViewAtIndex(index, ListView.Contain)
    }

    onDropAreaEntered: {
        root.skipMoveTransition = true
        itemModel.move(dragSource.itemIndex, index)
    }

    //property int moving: index
    //onMovingChanged: list.positionViewAtIndex(index, ListView.Center)
}
