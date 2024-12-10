import QtQuick
import QtQuick.Controls
import QDynamics

Control {
    id: root

    signal action()

    property Dimensions dimensions
    property bool editMode
    property double treshold: root.dimensions.mm(30)

    background: Rectangle { color: "black"; opacity: 0.8 }
    contentItem: TextIcon {
        text: root.editMode ? "\uf07a" : "\uf044"
        font: root.font
        color: root.height > root.treshold ? "#4CAF50" : "white"
        Behavior on color { ColorAnimation { } }
    }
    font { pixelSize: root.dimensions.mm(7) }
    resources: [
        Connections {
            target: root.visible ? root.parent : null
            function onDragEnded() {
                if (root.height < root.treshold) return;
                dealayAction.restart();
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
