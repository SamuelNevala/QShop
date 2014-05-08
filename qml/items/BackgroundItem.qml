import QtQuick 2.3

Item {
    id: root

    property alias color: background.color
    property alias border: background.border

    height: constants.maxHeight

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        opacity: 0.8
        Behavior on color { ColorAnimation { } }
    }
}
