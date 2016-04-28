import QtQuick 2.6

MouseArea {
    id: root

    property alias source: icon.source
    property alias text: text.text

    implicitHeight: theme.heights.medium

    BackgroundItem {
        anchors.fill: parent
        color: root.pressed || icon.pressed ? "lightgray" : "white"
    }

    IconButton {
        id: icon
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        overlayVisible: root.pressed
        width: height
        onClicked: root.clicked(mouse)
    }

    Text {
        id: text
        anchors { fill: parent; leftMargin: icon.width; rightMargin: theme.margins.medium }
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font {
            bold: true
            pixelSize: theme.fonts.medium
        }
    }
}
