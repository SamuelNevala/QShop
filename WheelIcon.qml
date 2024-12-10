import QtQuick

TextIcon {
    id: root

    color: "white"
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
