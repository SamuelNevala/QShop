import QtQuick 2.0

BackgroundItem {
    id: root

    property alias text: text

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
