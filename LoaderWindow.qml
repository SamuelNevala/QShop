pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

Window {
    id: window

    property alias asynchronous: loader.asynchronous
    property alias source: loader.source

    color: "black"
    visible: false

    Loader {
        id: loader

        asynchronous: true
        opacity: 0.2

        Behavior on opacity {
            DefaultAnimation {
                duration: 500
            }
        }

        onLoaded: {
            window.visible = true;
            opacity = 1.0;
        }

        anchors {
            fill: parent
        }
    }
}
