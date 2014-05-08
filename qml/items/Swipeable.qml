import QtQuick 2.3

MouseArea {
    id: root

    function resetX() { animate.to(0) }

    property int actionTreshold: Math.round(width / 2)
    property real opacityEnd: 0.6

    signal action(bool rightSide)

    drag.target: root
    drag.axis: Drag.XAxis
    drag.minimumX: -width
    drag.maximumX: width
    opacity: Math.max(opacityEnd,
                      1 - (Math.abs(x) / actionTreshold * opacityEnd))

    onReleased: {
        if (Math.abs(x) >= actionTreshold)
            animate.to(x > 0 ? drag.maximumX : drag.minimumX)
        else
            animate.to(0)
    }

    SequentialAnimation {
        id: animate

        function to(x) {
            xAnimation.from = drag.target.x
            xAnimation.to = x
            animate.restart()
        }

        NumberAnimation { id: xAnimation; target: drag.target; property: "x"; easing.type: Easing.InOutQuad }
        ScriptAction { script: if (drag.target.x != 0) root.action(drag.target.x > 0) }
    }
    propagateComposedEvents: mainView.editMode
    onClicked: mouse.accepted = !mainView.editMode
}
