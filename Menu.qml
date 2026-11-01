import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Controls.Material

Controls.Drawer {
    id: root

    bottomInset: Theme.pixels(2)
    topInset: Theme.pixels(2)
    bottomPadding: bottomInset + Theme.pixels(1) + SafeArea.margins.bottom
    topPadding: topInset + Theme.pixels(1) + SafeArea.margins.top
    leftPadding: Theme.pixels(1) + SafeArea.margins.left
    rightPadding: Theme.pixels(1) + SafeArea.margins.right

    Binding {
        target: root.background
        property: "color"
        value: Material.shade(root.Material.theme === Material.Dark ? "#FF424242" : "#FFFFFFFF",
                              Material.Shade800)
    }
}
