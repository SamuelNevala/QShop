import QtQuick 2.0

Input {
    id: input

    leftMargin: constants.minHeight

    BackButton {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left }
        height: constants.minHeight
        width: height
        onClicked: pageSwitcher.pop()
    }

    onAccepted: {
        itemModel.insert(index, input.text)
        input.text = ""
        list.positionViewAtIndex(index, ListView.Contain)
    }

    onDropAreaEntered: {
        //root.skipMoveTransition = true
        itemModel.move(dragSource.itemIndex, index)
    }

    //property int moving: index
    //onMovingChanged: list.positionViewAtIndex(index, ListView.Center)
}
