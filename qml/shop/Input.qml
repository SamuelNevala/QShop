import QtQuick 2.0
import QtQuick.Controls 1.0

Item {
    id: root
    signal accepted()
    property Item itemUnder
    property int itemUnderCenterY: itemUnder ? itemUnder.y + itemUnder.height / 2 - displacement : 0
    property int centerY: y + (height / 2)
    property int maxDrag
    property int displacement
    property bool atBottom: itemUnderCenterY - centerY <= 0
    property alias text: input.text
    property alias enabled: input.enabled

    height: 70
    opacity: enabled ? 1.0 : 0.0
    visible: opacity > 0.0

    TextField {
        id: input
        anchors { left: parent.left; right: parent.right; margins: 20; verticalCenter: parent.verticalCenter }
        font.pixelSize: 25
        horizontalAlignment: Text.AlignHCenter
        height: parent.height * 0.62
        onAccepted: root.accepted()
        opacity: 1
        z:1
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        opacity: 0.6
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        propagateComposedEvents: true
        drag.target: parent
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: root.maxDrag
        z: 1
    }

    Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
}
