import QtQuick 2.4

MouseArea {
    id: root

    property alias source: icon.source
    property alias text: text.text

    height: theme.heights.medium

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
            rightMargin: theme.margins.medium
        }
        verticalAlignment: Text.AlignVCenter
        color: "gray"
        font {
            bold: true
            pixelSize: theme.fonts.medium
        }
        maximumLineCount: 2
        wrapMode: Text.Wrap
    }
}
