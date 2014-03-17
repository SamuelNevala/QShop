import QtQuick 2.0

Item {
    id: root

    property alias color: background.color

    height: constants.maxHeight

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        opacity: 0.8
        Behavior on color { ColorAnimation { } }
    }
}
