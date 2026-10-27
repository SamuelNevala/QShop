import QtQuick
import QtQuick.Window

pragma ComponentBehavior: Bound

Window {
    id: window

    property alias asynchronous: loader.asynchronous
    property alias source: loader.source

    color: "black"
    visible: false

    Loader {
        id: loader

        anchors { fill: parent }
        asynchronous: true
        opacity: 0.2
        onLoaded: {
            window.visible = true
            opacity = 1.0
        }
        Behavior on opacity { DefaultAnimation { duration: 500 } }
    }
}
