import QtQuick 2.0
import QtGraphicalEffects 1.0

Rectangle {
    id: root
    property Item itemUnder: list.itemAt(input.x, input.y+input.height / 2 + list.contentY)
    property int itemCenterY: itemUnder ? itemUnder.y + itemUnder.height / 2 - list.contentY : 0
    anchors { left: parent.left; right: parent.right; }
    color: "#E1DA9A"
    height: 6
    opacity: enabled ? 1.0 : 0.0
    visible: opacity > 0.0
    y: itemUnder.y + ((itemCenterY - input.centerY) <= 0 ? itemUnder.height : 0) - height / 2 - list.contentY
    Behavior on y { NumberAnimation { easing.type: Easing.InOutQuad } }
    Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }

    RectangularGlow {
        id: effect
        anchors.fill: root
        glowRadius: 12
        spread: 0.2
        color: "#E1DA9A"
    }
}
