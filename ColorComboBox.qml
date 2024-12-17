import QtQuick
import QtQuick.Controls.Material
import QDynamics

ComboBox {
    id: root

    property Dimensions dimensions
    property alias label: label.text

    topInset: label.height + root.dimensions.mm(1)
    topPadding: topInset
    leftPadding: root.dimensions.mm(2)
    textRole: "text"
    valueRole: "color"

    model: ColorModel {}
    Text {
        id: label

        color: Material.primaryTextColor
        font { pixelSize: root.dimensions ? root.dimensions.mm(3) : 0 }
        fontSizeMode: Text.Fit
        x: parent.leftPadding
        width: parent.availableWidth
    }
}
