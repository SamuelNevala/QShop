import QtQuick.Controls.Material
import QtQuick
import QtQuick.Controls
Control {
    id: root

    signal action()
    property bool editMode
    property double treshold: Theme.pixels(30)

    background: Rectangle { color: Material.backgroundColor; opacity: 0.8 }
    contentItem: TextIcon {
        text: root.editMode ? "\uf07a" : "\uf044"
        font: root.font
        color: root.height > root.treshold ? Material.accentColor : Material.foreground
        Behavior on color { ColorAnimation { } }
    }
    font { pixelSize: Theme.pixels(7) }
    resources: [
        Connections {
            target: root.visible ? root.parent : null
            function onDragEnded() {
                if (root.height < root.treshold) {
                    return
                }
                dealayAction.restart()
            }
        },
        Timer {
            id: dealayAction
            interval: 450
            onTriggered: root.action()
        }
    ]
    z: -1
}
