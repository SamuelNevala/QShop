import QtQuick 2.6

Item {
    id: root

    property alias color: background.color
    property alias border: background.border

    implicitHeight: theme.heights.large

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        opacity: 0.8
        Behavior on color { ColorAnimation { } }
    }
}
