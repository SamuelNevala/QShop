import QtQuick.Controls.Material
import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    property color color: pressed ? Material.accentColor : Material.backgroundColor

    contentItem: TextIcon {
        color: root.color
        font: root.font
        text: root.text
    }

    font { pixelSize: Math.round(root.height * 0.75) }

    implicitHeight: Theme.pixels(9.27)
    opacity: enabled ? 1.0 : 0.2
    padding: Theme.pixels(0.2)

    Behavior on opacity { DefaultAnimation { id: opacityAnimation } }
}
