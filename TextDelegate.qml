import QtQuick.Controls.Material
import QtQuick
import QShopper
import QDynamics

pragma ComponentBehavior: Bound

Delegate {
    id: root

    signal doubleTapped()
    signal pressed()
    signal singleTapped
    signal swiped(int direction)

    property bool checked
    property Item dragParent
    property bool editMode

    SwipeHandler {
        id: swipeHandler

        function swiped(direction) {
            const temporary = root.index;
            root.swiped(direction);
            animateSwipe.reset(temporary === root.index ? 0 : 250);
        }

        dimensions: root.dimensions
        enabled: !tapHandler.longPressActive
        target: root
        onSwipe: (direction) => { animateSwipe.to(direction, 0); }
    }

    TapHandler {
        id: tapHandler

        property bool longPressActive: false

        enabled: root.editMode
        exclusiveSignals: TapHandler.SingleTap | TapHandler.DoubleTap
        target: root

        onDoubleTapped: root.doubleTapped();
        onGrabChanged: (transition, point) => {
            root.pressed();
            if (transition === PointerDevice.UngrabPassive) {
                longPressActive = false;
            }
        }
        onLongPressed: {
            if (root.checked) return;
            longPressActive = true;
        }
        onSingleTapped: root.singleTapped();
    }

    DragHandler {
        id: dragHandler

        enabled: tapHandler.longPressActive
        xAxis { enabled: false }
        yAxis { minimum: 0; maximum: root.dragParent.height }
    }

    Drag.active: swipeHandler.active || dragHandler.active
    Drag.hotSpot.y: Math.round(root.height / 2)
    Drag.hotSpot.x: Math.round(root.width / 2)
    Drag.source: root

    states: State {
        name: "drag"; when: dragHandler.active
        ParentChange { target: root; parent: root.dragParent }
        PropertyChanges { root { z: 1 } }
    }

    transitions: Transition { from: "drag"; ParentAnimation { } }

    background: Item {
        Rectangle {
            anchors { fill: parent }
            color: Material.backgroundColor
            opacity: Math.max(0.6, 0.8 - (Math.abs(root.x) / swipeHandler.actionTreshold * 0.6))
            Behavior on color { ColorAnimation { } }
        }

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            color: tapHandler.longPressActive ? Material.accentColor : "trasparent"
            height: root.dimensions.mm(0.4)
            opacity: tapHandler.longPressActive ? 1.0 : 0.0
            Behavior on color { ColorAnimation { } }
            Behavior on opacity { DefaultAnimation { } }
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            color: tapHandler.longPressActive ? Material.accentColor : "trasparent"
            height: root.dimensions.mm(0.4)
            opacity: tapHandler.longPressActive ? 1.0 : 0.0
            Behavior on color { ColorAnimation { } }
            Behavior on opacity { DefaultAnimation { } }
        }

        Rectangle {
            id: leftIconBackground
            anchors { bottom: parent.bottom; top: parent.top; right: parent.left }
            color: root.editMode ? Material.color(Material.Red) : Material.color(Material.Green)
            opacity: animateSwipe.running ? 0.0 : 0.8
            width: root.x
            Behavior on color { ColorAnimation { } }
            Behavior on opacity { DefaultAnimation { } }
        }

        IconChoser {
            anchors { bottom: parent.bottom; top: parent.top; left: leftIconBackground.left }
            checked: root.checked
            checkedIcon: CartOutIcon {
                font { family: root.font.family }
                ratio: root.x / width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
                Material.theme: ThemeManager.theme
            }
            editMode: root.editMode
            icon: CartInIcon {
                font { family: root.font.family }
                ratio: root.x / width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
            }
            trashIcon: TrashIcon {
                font { family: root.font.family }
                ratio: root.x / width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
                Material.theme: ThemeManager.theme
            }
            width: height
        }

        Rectangle {
            id: rightIconBackground

            anchors { bottom: parent.bottom; top: parent.top; left: parent.right }
            color: Material.color(Material.Green)
            opacity: animateSwipe.running ? 0.0 : 0.8
            width: -root.x
            Behavior on color { ColorAnimation { } }
            Behavior on opacity { DefaultAnimation { } }
        }

        IconChoser {
            id: rightIcon

            anchors { bottom: parent.bottom; top: parent.top; right: rightIconBackground.right }
            checked: root.checked
            checkedIcon: CartOutIcon {
                font { family: root.font.family }
                ratio: root.x / -width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
                Material.theme: ThemeManager.theme
            }
            icon: CartInIcon {
                font { family: root.font.family }
                ratio: root.x / -width
                opacity: animateSwipe.running ? 0.0 : Math.max(0.0, ratio)
            }
            transform: Scale { origin { x: rightIcon.width / 2; y: rightIcon.height / 2 } xScale: -1 }
            width: height
        }
    }

    contentItem: TextItem {
        checked: root.checked
        dimensions: root.dimensions
        text: root.name
        Material.theme: ThemeManager.theme
    }

    resources: [
        SequentialAnimation {
            id: animateSwipe

            property int direction: SwipeHandler.Direction.None

            function reset(delay) { to(SwipeHandler.Direction.None, delay); }

            function to(direction, delay) {
                xAnimation.from = root.x;
                if (direction === SwipeHandler.Direction.None) {
                    xAnimation.to = 0;
                } else {
                    xAnimation.to = direction === SwipeHandler.Direction.Right ? root.width : -root.width;
                }
                pause.duration = delay;
                animateSwipe.direction = direction;
                animateSwipe.restart();
            }

            PauseAnimation { id: pause }
            DefaultAnimation { id: xAnimation; target: root; property: "x" }

            onFinished: {
                if (animateSwipe.direction !== SwipeHandler.Direction.None) {
                    swipeHandler.swiped(animateSwipe.direction);
                }
            }
        }
    ]
    Material.theme: checked ? ThemeManager.inverseTheme : ThemeManager.theme
}
