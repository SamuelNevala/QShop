import QtQuick
import QtQuick.Controls
import QDynamics

AbstractButton {
    id: root

    property Dimensions dimensions
    property color color: pressed ? "#4CAF50" : "black"

    contentItem: TextIcon {
        color: root.color
        font: root.font
        text: root.text
    }

    font { pixelSize: Math.round(root.height * 0.75) }

    implicitHeight: dimensions ? dimensions.mm(9.27) : 0
    opacity: enabled ? 1.0 : 0.2
    padding: dimensions ? dimensions.mm(0.2) : 0

    Behavior on opacity { DefaultAnimation { id: opacityAnimation } }
}
