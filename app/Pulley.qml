import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Controls.Material

Controls.Control {
    id: root

    property bool editMode
    property double treshold: Theme.pixels(30)
    readonly property bool thresholdReached: {
        const flickable = parent as Flickable;
        return flickable !== null && enabled && visible && flickable.dragging && height >= treshold;
    }

    signal action

    z: -1

    background: Rectangle {
        color: Material.backgroundColor
        opacity: 0.8
    }
    contentItem: TextIcon {
        text: root.editMode ? "\uf07a" : "\uf044"
        font: root.font
        color: root.height > root.treshold ? Theme.readableInk(Material.accentColor,
                                                               root.Material.backgroundColor, 0.8,
                                                               3) : Material.foreground

        Behavior on color {
            ColorAnimation {}
        }
    }
    resources: [
        Connections {
            function onDragEnded() {
                if (root.height < root.treshold) {
                    return;
                }
                dealayAction.restart();
            }

            target: root.visible ? root.parent as Flickable : null
        },
        Timer {
            id: dealayAction

            interval: 450

            onTriggered: root.action()
        }
    ]

    onThresholdReachedChanged: {
        if (thresholdReached) {
            Haptics.play(Haptics.Confirm);
        }
    }

    font {
        pixelSize: Theme.pixels(7)
    }
}
