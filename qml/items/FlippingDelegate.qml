import QtQuick 2.0

Item {
    id: root
    property alias text: text
    property bool flip
    property alias color: background.color

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        opacity: 0.8
    }

    Text {
        id: text
        anchors {
            right: parent.right; left: parent.left; margins: 10
            verticalCenter: parent.verticalCenter
        }
        horizontalAlignment: Text.AlignHCenter
        font {
            bold: true
            pixelSize: parent.height - 20

        }
        color: "white"
        scale: parent.width / (paintedWidth + 20) < 1 ? parent.width / (paintedWidth + 20) : 1
    }
}
