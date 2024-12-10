import QtQuick
import Components
import Shop.timer

MouseArea {
    id: root

    function resetX(delay) {
        animate.to(0, delay)
    }

    property int actionTreshold: Math.round(width / 2)
    property real widthInMillimeters: dimensions.mm(width)
    property real opacityEnd: 0.6
    property real startX: 0.0
    property real swipeSensitivity: 1.0

    signal action(bool rightSide)
    
    implicitHeight: dimensions.mm(9.27)
    drag.target: root
    drag.axis: Drag.XAxis
    drag.minimumX: -width
    drag.maximumX: width
    opacity: Math.max(opacityEnd, 1 - (Math.abs(x) / actionTreshold * opacityEnd))
    //propagateComposedEvents: true
    
    resources: [
        ElapsedTimer { id: timer },
        Connections {
            target: dimensions
            function onScaleChanged() {
                widthInMillimeters = dimensions.mm(width);
                implicitHeight = dimensions.mm(9.27);
            }
        }
    ]

    onPressed: (mouse) => {
        startX = x;
        timer.start();
        mouse.accepted = true;
    }

    onReleased: (mouse) => {
        var elapsedTimeInSeconds = Math.abs(timer.elapsed() / 1000);
        var distanceInMilimeters = Math.abs(dimensions.mm(x - startX));
        var velocity = distanceInMilimeters / elapsedTimeInSeconds;
        // Grativy of this program is 9810 mm/s2 f = velocity^2 / gravity * sensitivity
        var force = velocity * velocity / 9810 * swipeSensitivity;
        // Calculate if swipe has enought fource to be selected.
        var selected = force >= widthInMillimeters;

        // Item can be selected by force or by long enought drag distance.
        if (selected || Math.abs(x) >= actionTreshold) {
            animate.to(x > 0 ? drag.maximumX : drag.minimumX, 0);
        } else {
            animate.to(0, 0);
        }
        mouse.accepted = true;
    }

    SequentialAnimation {
        id: animate

        function to(x, delay) {
            xAnimation.from = drag.target.x;
            xAnimation.to = x;
            pause.duration = delay;
            animate.restart();
        }

        PauseAnimation { id: pause }
        DefaultAnimation { id: xAnimation; target: drag.target; property: "x" }
        ScriptAction { script: {
                if (drag.target.x != 0) {
                    root.action(drag.target.x > 0);
                }
                pause.duration = 0;
            }
        }
    }
}
