import QtQuick.Controls.Material as Style
import QtQuick
import QDynamics

Style.GroupBox {
    id: root

    property Dimensions dimensions
    // spacing: root.dimensions.mm(5)
    // leftInset: root.dimensions.mm(5)
    // rightInset: root.dimensions.mm(5)
    // topPadding: root.dimensions.mm(2)
    // bottomPadding: root.dimensions.mm(2)
    // padding: root.dimensions.mm(2)
    // topInset: label.height

    // label: Text {
    //     color: Style.Material.primaryTextColor
    //     font { pixelSize: root.dimensions ? root.dimensions.mm(3) : 0 }
    //     fontSizeMode: Text.Fit
    //     text: root.title
    //     x: root.leftInset
    //     width: root.availableWidth
    // }
}
