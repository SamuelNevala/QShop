import QtQuick 2.0

Rectangle {
    id: root

    property string pullHint
    property string actionText
    property real actionThreshold: parent.height * 0.1
    property bool active: height > 0.0

    signal action()

    anchors {
        top: parent.top
        left: parent.left; right: parent.right
    }
    color: "black"
    height: -parent.contentY - parent.headerItem.height
    opacity: 0.8
    z: -1

    Text {
        anchors {
            left: parent.left; right: parent.right
            bottom: parent.bottom
            bottomMargin: Math.round(actionThreshold / 2) - Math.round(height / 2)
        }
        font { pixelSize: 35; bold: true }
        color: "white"
        text: parent.height > actionThreshold ? actionText : pullHint
        horizontalAlignment: Text.AlignHCenter
    }

    Connections {
        target: root.parent
        onDragEnded:{
            //console.log(root.height, actionThreshold, root.height > actionThreshold)
            if (root.height > actionThreshold) root.action()
        }
    }

}
