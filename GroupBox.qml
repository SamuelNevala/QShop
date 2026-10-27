import QtQuick
import QtQuick.Controls.Material as Controls

pragma ComponentBehavior: Bound

Controls.GroupBox {
    id: root

    font.pixelSize: Theme.pixels(3.5)
    spacing: Theme.pixels(1)
    padding: Theme.pixels(4)
    topInset: implicitLabelHeight + spacing
    topPadding: topInset + padding
    bottomPadding: padding

    label: Text {
        x: root.padding
        width: root.availableWidth
        text: root.title
        color: root.Controls.Material.primaryTextColor
        font.pixelSize: Theme.pixels(3)
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.pixels(1)
        color: "transparent"
        border.width: Theme.pixels(0.4)
        border.color: root.activeFocus ? root.Controls.Material.accentColor
            : root.enabled && root.hovered ? root.Controls.Material.primaryTextColor
            : root.Controls.Material.hintTextColor
    }
}
