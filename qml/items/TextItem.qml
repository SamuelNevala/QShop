import QtQuick 2.2

BackgroundItem {
    id: root

    property alias text: text

    Text {
        id: text
        anchors.centerIn: parent
        height: parent.height
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "white"
        font {
            bold: true
            pixelSize: parent.height * 0.8
        }
        fontSizeMode: Text.Fit
        maximumLineCount: 2
        wrapMode: Text.Wrap
    }
}
