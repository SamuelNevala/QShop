import QtQuick 2.3
import QtQuick.Controls 1.1

Input {
    id: input

    function addItem() {
        if (input.text === "") return
        itemModel.insert(index, input.text)
        input.text = ""
        mainView.positionViewAtIndex(index, ListView.Contain)
    }

    leftMargin: constants.minHeight
    rightMargin: constants.minHeight
    placeholderText: qsTr("Tap to insert items")
    placeholderTextFocus: qsTr("Write new item")

    IconButton {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left }
        height: constants.minHeight
        source: "qrc:/pic/menu"
        width: height
        onClicked: {
            sideBar.open()
        }
    }

    IconButton {
        anchors { verticalCenter: parent.verticalCenter; right: parent.right}
        height: constants.minHeight
        width: height
        source: "qrc:/pic/new"
        onClicked: {
            Qt.inputMethod.commit()
            addItem()
        }
    }

    onAccepted: addItem()

    onDropAreaEntered: itemModel.move(dragSource.itemIndex, index)
}
