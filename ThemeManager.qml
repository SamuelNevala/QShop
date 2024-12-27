pragma Singleton
import QtQuick.Controls.Material
import QtCore
import QtQuick

Settings {
    property var accent: value("accent", Material.Green)
    property int inverseTheme: theme === Material.Dark ? Material.Light : Material.Dark;
    property var primary: value("primary", Material.Indigo)
    property int theme: value("theme", Material.Dark)
    property string activeList: value("activeList", "default")
}
