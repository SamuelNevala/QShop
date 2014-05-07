import QtQuick 2.2

Swipeable {
    id: root

    dragThreshold: applicationWindow.dragDistance
    height: constants.maxHeight
    target: rect

    Flipable {
        id: rect
        anchors.fill: parent
        transform: root.rotation

        front: TextItem {
            anchors { fill: rect }
            text { text: itemText; color: "white" }
        }

        back: TextItem {
            anchors.fill: rect
            text {
                text: itemText
                font.strikeout: true
                color: "darkgray"
            }
        }
    }

    onSideChanged: itemModel.toggleSelected(index)
    Component.onCompleted: root.setStartSide(selected)
}
