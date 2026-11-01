import QtQuick

DragHandler {
    enum Direction {
        Left,
        Right,
        None
    }

    property int actionTreshold: Math.round(target.width / 2)
    property real swipeSensitivity: Theme.swipeSensitivity
    property real widthInMillimeters: Theme.millimeters(target.width)

    signal swipe(int direction)

    onGrabChanged: (transition, point) => {
        if (transition !== PointerDevice.UngrabExclusive && transition
                !== PointerDevice.CancelGrabExclusive) {
            return;
        }

        // TouchCancel can ungrab without a release; it must only return the row.
        if (transition === PointerDevice.CancelGrabExclusive || point.state
                !== EventPoint.Released) {
            swipe(SwipeHandler.Direction.None);
            return;
        }

        const distance = Math.abs(point.pressPosition.x - point.position.x);
        const distanceInMilimeters = Theme.millimeters(distance);
        const velocity = distanceInMilimeters / point.timeHeld;
        // Make 100% match the phone-tested feel of 150% at 1000 mm/s².
        const gravity = 666.67;
        const force = velocity * velocity / gravity * swipeSensitivity;
        // Calculate if swipe has enought force to be selected.
        const selected = force >= widthInMillimeters;

        // Item can be selected by force or by long enought drag distance.
        if (selected || distance >= actionTreshold) {
            swipe(target.x > 0 ? SwipeHandler.Direction.Right : SwipeHandler.Direction.Left);
        } else {
            swipe(SwipeHandler.Direction.None);
        }
    }

    xAxis {
        minimum: -target.width
        maximum: target.width
    }

    yAxis {
        enabled: false
    }
}
