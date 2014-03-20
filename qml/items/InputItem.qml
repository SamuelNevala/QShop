import QtQuick 2.0

Input {
    id: input

    leftMargin: constants.minHeight
    placeholderText: qsTr("Tap to insert items")
    placeholderTextFocus: qsTr("Write new item")

    BackButton {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left }
        height: constants.minHeight
        width: height
        onClicked: pageSwitcher.pop()
    }

    onAccepted: {
        itemModel.insert(index, input.text)
        input.text = ""
        editList.positionViewAtIndex(index, ListView.Contain)
    }

    onDropAreaEntered: itemModel.move(dragSource.itemIndex, index)
}
