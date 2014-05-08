import QtQuick 2.3
import Shop.extra 1.0

MouseArea {
    id: root

    function open() {
        animate.toX(drag.maximumX)
    }


    function close() {
        animate.toX(drag.minimumX)
        focusHolder.forceActiveFocus()
    }

    default property alias content: menu.children

    drag.target: root
    drag.axis: Drag.XAxis
    drag.minimumX: -width + constants.margin
    drag.maximumX: 0

    Rectangle {
        id: menu
        anchors {
            fill: parent
            rightMargin: constants.margin
        }
        color: "white"
    }

    Rectangle {
        id: dimmer
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.right
            leftMargin: -constants.margin
        }
        width: applicationWindow.width
        color: "black"
        opacity: Math.max(0.0, 0.8 - Math.abs(root.x) / (root.width + constants.margin))
        visible: opacity

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: false
            enabled: dimmer.visible
            onClicked: animate.toX(root.drag.minimumX)
        }
    }

    onReleased: {
        if (Math.abs(x) < width / 2)
            animate.toX(drag.maximumX)
        else
            animate.toX(drag.minimumX)
    }

    NumberAnimation {
        id: animate;

        function toX(x) {
            if (x === drag.maximumX) root.forceActiveFocus()
            animate.from = drag.target.x
            animate.to = x
            animate.restart()
        }

        target: drag.target
        property: "x"
        easing.type: Easing.InOutQuad
    }

    HwKeyWatcher {
        target: root
        onBackClicked: close()
    }
}
