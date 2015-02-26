import QtQuick 2.4
import Shop.timer 1.0

MouseArea {
    id: root

    function resetX(delay)
    {
        animate.to(0, delay)
    }

    property int actionTreshold: Math.round(width / 2)
    property real widthmm: width / theme.pixelDensity
    property real opacityEnd: 0.6
    property real startPos
    property real endPos

    signal action(bool rightSide)

    drag.target: root
    drag.axis: Drag.XAxis
    drag.minimumX: -width
    drag.maximumX: width
    opacity: Math.max(opacityEnd, 1 - (Math.abs(x) / actionTreshold * opacityEnd))

    onPressed: {
        startPos = x
        timer.start()
    }

    onReleased: {
        var elapsedTime = timer.elapsed()
        endPos = x

        var velocity = Math.abs((endPos - startPos) / theme.pixelDensity) / Math.abs(elapsedTime / 1000)
        // Grativy of this program is 205 mm/s2
        var selected = velocity * velocity / 205 >= widthmm

        if (selected || Math.abs(x) >= actionTreshold)
            animate.to(x > 0 ? drag.maximumX : drag.minimumX, 0)
        else
            animate.to(0, 0)
    }

    ElapsedTimer { id: timer }

    SequentialAnimation {
        id: animate

        function to(x, delay) {
            xAnimation.from = drag.target.x
            xAnimation.to = x
            pause.duration = delay
            animate.restart()
        }

        PauseAnimation { id: pause }
        DefaultAnimation { id: xAnimation; target: drag.target; property: "x" }
        ScriptAction { script: {
                if (drag.target.x != 0) root.action(drag.target.x > 0)
                pause.duration = 0
            }
        }
    }

    propagateComposedEvents: mainView.editMode
    onClicked: mouse.accepted = !mainView.editMode
}
