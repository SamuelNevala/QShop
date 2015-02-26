import QtQuick 2.4
import QtQuick.Controls 1.3

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
