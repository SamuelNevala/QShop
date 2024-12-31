import QtQuick.Controls.Material
import QtQuick
import QDynamics

LoaderWindow {

    source: Qt.resolvedUrl("View.qml")
    title: qsTr("QShopper")
    type: Dimensions.Phone

    Material.accent: ThemeManager.accentColor()
    Material.primary: ThemeManager.primaryColor()
    Material.theme: ThemeManager.theme
}

