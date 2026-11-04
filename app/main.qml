import QtCore
import QtQuick
import QtQuick.Controls.Material

LoaderWindow {
    id: window

    // Defer resizing until the current screen/DPI notification has finished.
    function updateWindowSize() {
        width = Math.round(Theme.pixels(76.6));
        height = Math.round(Theme.pixels(162.8));
    }

    color: Material.backgroundColor
    title: qsTr("QShopper") + (Theme.scaleable ? " (" + Math.round(Theme.effectiveScale * 100)
                                                 + "%)" : "")
    source: Qt.resolvedUrl("View.qml")
    Material.accent: Theme.accentColor()
    Material.primary: Theme.primaryColor()
    Material.theme: Theme.theme

    Component.onCompleted: Qt.callLater(window.updateWindowSize)

    Connections {
        function onPixelsPerMillimeterChanged() {
            Qt.callLater(window.updateWindowSize);
        }

        target: Theme
    }

    Shortcut {
        sequence: "PgUp"
        enabled: Theme.scaleable

        onActivated: Theme.scaleUp()
    }

    Shortcut {
        sequence: "PgDown"
        enabled: Theme.scaleable

        onActivated: Theme.scaleDown()
    }

    Shortcut {
        sequence: "Ctrl+0"
        enabled: Theme.scaleable

        onActivated: Theme.scale = 1.0
    }

    Settings {
        property alias x: window.x
        property alias y: window.y

        category: "Window"
    }

    Binding {
        target: Theme
        property: "parent"
        value: window.contentItem
    }
}
