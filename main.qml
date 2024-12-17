import QtQuick.Controls.Material
import QtQuick
import QDynamics

LoaderWindow {

    function color(color) {
        return Material.color(color, Material.theme === Material.Dark ? Material.Shade200 : Material.Shade500)
    }

    source: Qt.resolvedUrl("View.qml")
    title: qsTr("QShopper")
    type: Dimensions.Phone

    Material.accent: color(ThemeManager.accent)
    Material.primary: color(ThemeManager.primary)
    Material.theme: ThemeManager.theme
}
