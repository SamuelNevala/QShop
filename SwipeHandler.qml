import QtQuick
DragHandler {
    enum Direction {
        Left,
        Right,
        None
    }

    signal swipe(int direction)

    property int actionTreshold: Math.round(target.width / 2)
    property real swipeSensitivity: Theme.swipeSensitivity
    property real widthInMillimeters: Theme.millimeters(target.width)

    xAxis {
        minimum: -target.width
        maximum: target.width
    }

    yAxis { enabled: false }

    onGrabChanged: (transition, point) => {
        if (transition !== PointerDevice.UngrabExclusive) {
            return;
        }

        const distance = point.pressPosition.x - point.position.x;
        const distanceInMilimeters = Math.abs(Theme.millimeters(distance))
        const velocity = distanceInMilimeters / point.timeHeld;
        // Grativy of this program is 9810 mm/s2 f = velocity^2 / gravity * sensitivity
        const force = velocity * velocity / 9810 * swipeSensitivity;
        // Calculate if swipe has enought force to be selected.
        const selected = force >= widthInMillimeters;

        // Item can be selected by force or by long enought drag distance.
        if (selected || distance >= actionTreshold) {
            swipe(target.x > 0 ? SwipeHandler.Direction.Right : SwipeHandler.Direction.Left);
        } else {
            swipe(SwipeHandler.Direction.None);
        }
    }
}
