import QtQuick.Controls.Material
import QtQuick
import QtQuick.Controls
import QDynamics

Drawer {
    id: root
    property Dimensions dimensions

    bottomInset: dimensions.mm(2); topInset: dimensions.mm(2)
    bottomPadding: bottomInset + dimensions.mm(1);  topPadding: topInset + dimensions.mm(1)
    leftPadding: dimensions.mm(1)
    rightPadding: dimensions.mm(1)

    Binding {
        target: root.background
        property: "color"
        value: Material.shade(ThemeManager.theme === Material.Dark ? "#FF424242" : "#FFFFFFFF", Material.Shade800)
    }
}
