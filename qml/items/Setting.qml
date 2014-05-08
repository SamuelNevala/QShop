import QtQuick 2.3

MouseArea {
    id: root

    property alias source: icon.source
    property alias text: text.text

    height: constants.minHeight

    BackgroundItem {
        anchors.fill: parent
        color: root.pressed || icon.pressed ? "lightgray" : "white"
        border {
            color: "gray"
            width: 1
        }
    }

    IconButton {
        id: icon
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        overlayVisible: root.pressed
        width: height
        onClicked: root.clicked(mouse)
    }

    Text {
        id: text
        anchors {
            fill: parent
            leftMargin: icon.width
            rightMargin: constants.margin
        }
        verticalAlignment: Text.AlignVCenter
        color: "gray"
        font {
            bold: true
            pixelSize: parent.height * 0.8
        }
        fontSizeMode: Text.Fit
        maximumLineCount: 2
        wrapMode: Text.Wrap
    }
}
