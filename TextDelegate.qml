pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material

Delegate {
    id: root

    property bool checked
    property Item dragParent
    property bool editMode

    signal doubleTapped
    signal pressed
    signal singleTapped
    signal swiped(int direction)

    Drag.active: swipeHandler.active || dragHandler.active
    Drag.hotSpot.y: Math.round(root.height / 2)
    Drag.hotSpot.x: Math.round(root.width / 2)
    Drag.source: root
    Material.theme: checked ? Theme.inverseTheme : Theme.theme

    states: State {
        name: "drag"
        when: tapHandler.longPressActive

        ParentChange {
            target: root
            parent: root.dragParent
        }

        PropertyChanges {
            root {
                z: 1
            }
        }
    }
    transitions: Transition {
        from: "drag"

        ParentAnimation {}
    }
    background: Item {
        Rectangle {
            color: Material.backgroundColor
            opacity: Math.max(0.6, 0.8 - (Math.abs(root.x) / swipeHandler.actionTreshold * 0.6))

            Behavior on color {
                ColorAnimation {}
            }

            anchors {
                fill: parent
            }
        }

        Rectangle {
            color: tapHandler.longPressActive ? Material.accentColor : "transparent"
            height: Theme.pixels(0.4)
            opacity: tapHandler.longPressActive ? 1.0 : 0.0

            Behavior on color {
                ColorAnimation {}
            }
            Behavior on opacity {
                DefaultAnimation {}
            }

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
        }

        Rectangle {
            color: tapHandler.longPressActive ? Material.accentColor : "transparent"
            height: Theme.pixels(0.4)
            opacity: tapHandler.longPressActive ? 1.0 : 0.0

            Behavior on color {
                ColorAnimation {}
            }
            Behavior on opacity {
                DefaultAnimation {}
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
        }

        Rectangle {
            id: leftIconBackground

            color: root.editMode ? Material.color(Material.Red) : Material.color(Material.Green)
            opacity: animateSwipe.running ? 0.0 : 0.8
            width: root.x

            Behavior on color {
                ColorAnimation {}
            }
            Behavior on opacity {
                DefaultAnimation {}
            }

            anchors {
                bottom: parent.bottom
                top: parent.top
                right: parent.left
            }
        }

        IconChoser {
            checked: root.checked
            editMode: root.editMode
            width: height

            checkedIcon: CartOutIcon {
                ratio: root.x / width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
                Material.theme: Theme.theme

                font {
                    family: root.font.family
                }
            }
            icon: CartInIcon {
                ratio: root.x / width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)

                font {
                    family: root.font.family
                }
            }
            trashIcon: TrashIcon {
                ratio: root.x / width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
                Material.theme: Theme.theme

                font {
                    family: root.font.family
                }
            }

            anchors {
                bottom: parent.bottom
                top: parent.top
                left: leftIconBackground.left
            }
        }

        Rectangle {
            id: rightIconBackground

            color: Material.color(Material.Green)
            opacity: animateSwipe.running ? 0.0 : 0.8
            width: -root.x

            Behavior on color {
                ColorAnimation {}
            }
            Behavior on opacity {
                DefaultAnimation {}
            }

            anchors {
                bottom: parent.bottom
                top: parent.top
                left: parent.right
            }
        }

        IconChoser {
            id: rightIcon

            checked: root.checked
            width: height

            checkedIcon: CartOutIcon {
                ratio: root.x / -width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
                Material.theme: Theme.theme

                font {
                    family: root.font.family
                }
            }
            icon: CartInIcon {
                ratio: root.x / -width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)

                font {
                    family: root.font.family
                }
            }
            transform: Scale {
                xScale: -1

                origin {
                    x: rightIcon.width / 2
                    y: rightIcon.height / 2
                }
            }

            anchors {
                bottom: parent.bottom
                top: parent.top
                right: rightIconBackground.right
            }
        }
    }
    contentItem: TextItem {
        checked: root.checked
        text: root.name
        Material.theme: Theme.theme
    }
    resources: [
        SequentialAnimation {
            id: animateSwipe

            property int direction: SwipeHandler.Direction.None

            function reset(delay) {
                to(SwipeHandler.Direction.None, delay);
            }

            function to(direction, delay) {
                xAnimation.from = root.x;
                if (direction === SwipeHandler.Direction.None) {
                    xAnimation.to = 0;
                } else {
                    xAnimation.to = direction === SwipeHandler.Direction.Right ? root.width :
                                                                                 -root.width;
                }
                pause.duration = delay;
                animateSwipe.direction = direction;
                animateSwipe.restart();
            }

            onFinished: {
                if (animateSwipe.direction !== SwipeHandler.Direction.None) {
                    swipeHandler.swiped(animateSwipe.direction);
                }
            }

            PauseAnimation {
                id: pause
            }

            DefaultAnimation {
                id: xAnimation

                target: root
                property: "x"
            }
        }
    ]

    SwipeHandler {
        id: swipeHandler

        function swiped(direction) {
            const temporary = root.index;
            root.swiped(direction);
            animateSwipe.reset(temporary === root.index ? 0 : 250);
        }

        enabled: !tapHandler.longPressActive
        target: root

        onSwipe: direction => {
            animateSwipe.to(direction, 0);
        }
    }

    DragHandler {
        id: dragHandler

        xAxis {
            enabled: false
        }

        yAxis {
            minimum: 0
            maximum: root.dragParent.height
            enabled: tapHandler.longPressActive
        }
    }

    Loader {
        id: tapHandler

        property bool longPressActive: false

        function resetRecognizer() {
            const handler = item as TapHandler;
            if (handler) {
                handler.enabled = false;
            }
            active = false;
            active = true;
        }

        sourceComponent: TapHandler {
            parent: root
            enabled: root.editMode
            exclusiveSignals: TapHandler.SingleTap | TapHandler.DoubleTap
            target: root

            onDoubleTapped: root.doubleTapped()
            onEnabledChanged: {
                if (!enabled) {
                    tapHandler.longPressActive = false;
                }
            }
            onGrabChanged: (transition, point) => {
                root.pressed();
                if (transition === PointerDevice.UngrabPassive || transition
                        === PointerDevice.CancelGrabPassive) {
                    tapHandler.longPressActive = false;
                    // Qt 6.12 can ungrab a cancelled touch but leave its hold timer pressed.
                    // Replace only that stale recognizer, after this event finishes.
                    if (pressed && point.state !== EventPoint.Released) {
                        Qt.callLater(tapHandler.resetRecognizer);
                    }
                }
            }
            onLongPressed: {
                if (!enabled || root.checked || point.id < 0) {
                    return;
                }
                tapHandler.longPressActive = true;
            }
            onSingleTapped: root.singleTapped()
        }
    }
}
