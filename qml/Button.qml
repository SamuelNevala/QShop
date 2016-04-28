import QtQuick 2.6

MouseArea {
    id: root
    property alias icon: icon.text
    property color color: "black"

    implicitHeight: theme.heights.large
    implicitWidth: icon.implicitWidth
    visible: enabled

    Text {
        id: icon
        anchors { fill: parent }
        font { pixelSize: Math.round(root.height * 0.75 ) }
        color: pressed ? "#33B5E5" : root.color
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Behavior on color { ColorAnimation { } }
    }
}
