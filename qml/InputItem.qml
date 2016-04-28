import QtQuick 2.6
import Qt.labs.controls 1.0 as Controls
import Shop.extra 1.0

Controls.TextField {
    id: root

    function addItem() {
        if (text === "") return
        itemModel.insert(index, text)
        text = ""
        mainView.positionViewAtIndex(index, ListView.Contain)
    }

    leftPadding: height
    rightPadding: height
    background:  Rectangle { color: "white"; opacity: 0.8 }
    focus: true
    font { pixelSize: theme.fonts.medium }
    height: theme.heights.large
    horizontalAlignment: Text.AlignHCenter
    placeholderText: qsTr("Tap to insert items")

    onAccepted: addItem()

    Keys.onReturnPressed: {
        Qt.inputMethod.commit()
        addItem()
    }

    Voice {
        onAdd: {
            root.text = text
            Qt.inputMethod.commit()
            addItem()
        }
        onClear: root.text = ""
        onRemove: mainView.deleteIndex = index - 1
    }

    DropArea {
        anchors { fill: parent }
        onEntered: itemModel.move(drag.source.itemIndex, index)
        enabled: true
    }

    Button {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left }
        height: parent.height
        icon: "\uf0c9"
        width: height
        onClicked: sideBar.open()
    }

    Button {
        anchors { verticalCenter: parent.verticalCenter; right: parent.right }
        height: parent.height
        icon: "\uf067"
        width: height
        onClicked: {
            Qt.inputMethod.commit()
            addItem()
        }
    }
}
