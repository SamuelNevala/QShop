import QtQuick 2.6
import Qt.labs.controls 1.0 as Controls
import Shop.extra 1.0

Input {
    id: input

    function addItem() {
        if (input.text === "") return
        itemModel.insert(index, input.text)
        input.text = ""
        mainView.positionViewAtIndex(index, ListView.Contain)
    }

    padding: theme.heights.medium
    placeholderText: qsTr("Tap to insert items")
    placeholderTextFocus: qsTr("Write new item")

    IconButton {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left }
        height: theme.heights.medium
        source: "qrc:/menu"
        width: height
        onClicked: sideBar.open()
    }

    IconButton {
        anchors { verticalCenter: parent.verticalCenter; right: parent.right}
        height: theme.heights.medium
        width: height
        source: "qrc:/new"
        onClicked: {
            Qt.inputMethod.commit()
            addItem()
        }
    }

    onAccepted: addItem()
    onDropAreaEntered: itemModel.move(dragSource.itemIndex, index)
}
