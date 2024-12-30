import QtQuick.Controls.Material
import QtQuick
import QDynamics

LoaderWindow {

    function color(color) {
        return Material.color(color, Material.theme === Material.Dark ? Material.Shade200 : Material.Shade500)
    }

    function colorAccent(color) {
        return Material.color(color, Material.theme === Material.Dark ? Material.ShadeA200 : Material.ShadeA400)
    }

    source: Qt.resolvedUrl("View.qml")
    title: qsTr("QShopper")
    type: Dimensions.Phone

    Material.accent: colorAccent(ThemeManager.accent)
    Material.primary: color(ThemeManager.primary)
    Material.theme: ThemeManager.theme
}

