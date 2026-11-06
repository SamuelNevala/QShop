pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Controls.Popup {
    id: root

    property string message

    signal undoRequested
    signal expired

    function restart() {
        undoExpiry.restart();
    }

    objectName: "undoBar"
    height: Theme.pixels(9.27)
    modal: false
    dim: false
    focus: false
    closePolicy: Controls.Popup.NoAutoClose
    padding: 0
    Material.theme: Theme.inverseTheme
    Material.roundedScale: Material.SmallScale

    contentItem: RowLayout {
        objectName: "undoAction"
        spacing: Theme.pixels(1)
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Undo")
        Accessible.description: root.message

        Accessible.onPressAction: root.undoRequested()

        Controls.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.pixels(2)
            text: root.message
            color: Theme.Material.primaryTextColor
            elide: Text.ElideRight
            font.family: Application.font.family
            font.pixelSize: Theme.pixels(3.5)
        }

        TextIcon {
            Layout.preferredWidth: Theme.pixels(9.27)
            Layout.fillHeight: true
            Layout.rightMargin: Theme.pixels(0.5)
            text: "\uf0e2"
            font.family: root.font.family
            font.pixelSize: Theme.pixels(5)
            color: Theme.Material.primaryTextColor
        }

        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: root.undoRequested()
        }
    }
    background: Controls.ProgressBar {
        id: undoProgress

        objectName: "undoCountdown"
        // Decorative timing feedback; the message and Undo action are accessible.
        Accessible.ignored: true
        value: 1
        padding: 0

        background: Rectangle {
            color: Theme.Material.backgroundColor
            radius: root.Material.roundedScale
        }
        contentItem: Item {
            Rectangle {
                objectName: "undoRemainingFill"
                width: parent.width * undoProgress.position
                height: parent.height
                radius: root.Material.roundedScale
                color: Theme.accentFillColor()
            }
        }
    }

    onClosed: undoExpiry.stop()

    NumberAnimation {
        id: undoExpiry

        objectName: "undoExpiry"
        target: undoProgress
        property: "value"
        from: 1
        to: 0
        duration: 15000
        paused: running && (!root.enabled || Application.state !== Qt.ApplicationActive)

        onFinished: root.expired()
    }
}
