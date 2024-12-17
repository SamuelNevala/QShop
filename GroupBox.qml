import QtQuick.Controls.Material as Style
import QtQuick
import QDynamics

Style.GroupBox {
    id: root

    property Dimensions dimensions
    spacing: root.dimensions.mm(1)
    padding: root.dimensions.mm(2)

    label: Text {
        color: Style.Material.primaryTextColor
        font { pixelSize: root.dimensions ? root.dimensions.mm(3) : 0 }
        fontSizeMode: Text.Fit
        text: root.title
        x: root.leftPadding
        width: root.availableWidth
    }
}
