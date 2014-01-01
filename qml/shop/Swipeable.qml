import QtQuick 2.0

MouseArea {
    id: root

    property real dragThreshold: 30
    property real maxThreshold: 150
    property int startAngle: 0
    property int maxAngle: 70
    property real angle: Math.max(Math.min(Math.min(distance, maxThreshold) / ratio, maxAngle), -maxAngle) + startAngle
    property real distance: mouseX - startX
    property real ratio: maxThreshold / maxAngle
    property real startX
    property bool finished: pressed && Math.abs(mouseX - startX) >= maxThreshold
    property alias active: root.preventStealing
    property bool directionLeft: mouseX - startX >= 0
    property alias rotation: rot
    property Item target

    signal sideChanged

    function setStartSide(back) {
        if (Math.abs(rot.angle) === back ? 180 : 0) return
        anim.duration = 0
        startAngle = rot.targetAngle = back ? 180 : 0
        anim.duration = 250
    }



    enabled: !anim.running
    preventStealing: pressed && Math.abs(distance) >= dragThreshold
    onPressed: startX = mouseX
    onReleased: {
        if (!active || !finished) { return }
        startAngle = rot.targetAngle = finished && rot.targetAngle == 0 ? (directionLeft  ? 180 : -180) : 0
    }

    z: preventStealing ? 1 : 0

    Rotation {
        id: rot
        property int targetAngle: 0
        origin.x: target.width/2
        origin.y: target.height/2
        axis.x: 0; axis.y: 1; axis.z: 0
        angle: drag.active ? 0 : (root.active ? root.angle : targetAngle)
        Behavior on angle { RotationAnimation { id:anim; direction: RotationAnimation.Shortest } }
        onAngleChanged: {
            if (Math.abs(angle) == 180 && Math.abs(root.angle) == 250
             || Math.abs(angle) == 0 && Math.abs(root.angle) == 70)
                root.sideChanged();
        }
    }
}
