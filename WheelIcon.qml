import QtQuick.Controls.Material
import QtQuick

TextIcon {
    id: root

    color: Material.primaryTextColor
    text: "\uf013"

    NumberAnimation {
        duration: 800
        from: 0; to: 360
        property: "rotation"
        running: true
        loops: Animation.Infinite
        target: root
    }
}
