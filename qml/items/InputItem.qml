import QtQuick 2.2
import QtQuick.Controls 1.1

Input {
    id: input

    function addItem() {
        if (input.text === "") return
        itemModel.insert(index, input.text)
        input.text = ""
        editList.positionViewAtIndex(index, ListView.Contain)
    }

    leftMargin: constants.minHeight
    rightMargin: constants.minHeight
    placeholderText: qsTr("Tap to insert items")
    placeholderTextFocus: qsTr("Write new item")

    IconButton {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left }
        height: constants.minHeight
        source: "qrc:/pic/previous"
        width: height
        onClicked: {
            Qt.inputMethod.hide()
            pageSwitcher.pop()
        }
    }

    IconButton {
        anchors { verticalCenter: parent.verticalCenter; right: parent.right}
        height: constants.minHeight
        width: height
        source: "qrc:/pic/new"
        onClicked: {
            Qt.inputMethod.commit()
            Qt.inputMethod.reset()
            addItem()
        }
    }

    onAccepted: addItem()

    onDropAreaEntered: itemModel.move(dragSource.itemIndex, index)
}
