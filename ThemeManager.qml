pragma Singleton
import QtQuick.Controls.Material
import QtCore
import QtQuick

Settings {
    function accentColor() {
        return colorAccent(accent);
    }

    function primaryColor() {
        return color(primary);
    }

    function color(value) {
        return Material.color(value, Material.theme === Material.Dark ? Material.Shade200 : Material.Shade500)
    }

    function colorAccent(value) {
        if (value == Material.Grey || value == Material.Brown || value == Material.BlueGrey) {
            return color(value);
        }
        return Material.color(value, Material.theme === Material.Dark ? Material.ShadeA200 : Material.ShadeA400)
    }

    property var accent: value("accent", Material.Green)
    property int inverseTheme: theme === Material.Dark ? Material.Light : Material.Dark;
    property var primary: value("primary", Material.Indigo)
    property int theme: value("theme", Material.Dark)
    property string activeList: value("activeList", "default")
}
