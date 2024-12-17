import QtQuick

Icon {
    id: root

    signal timeout()

    background: Canvas {
        id: canvas

        property real angle: base * 9
        property real arcY: height / 2
        property real arcX: width / 2
        property real base: Math.PI / 5
        property real delay: 1.0
        property real lineWidth: root.dimensions.mm(0.5)
        property real startAngle: base * 3
        property real radius: arcX - lineWidth

        NumberAnimation {
            id: animateDelay
            duration: 15000
            from: 1.0; to: 0.0
            property: "delay"
            target: canvas
            onFinished: root.timeout()
        }

        onDelayChanged: requestPaint()
        onPaint: {
            const context = getContext("2d");
            context.clearRect(0, 0, width, height);
            context.strokeStyle = root.color;
            context.lineWidth = lineWidth;
            context.beginPath();
            const endAngle = startAngle + delay * angle;
            context.arc(arcX, arcX, radius, startAngle, endAngle);
            context.stroke();
        }
    }
    bottomInset: root.dimensions.mm(0.5); topInset: bottomInset
    leftInset: bottomInset; rightInset: bottomInset
    padding: root.dimensions.mm(2)
    text: "\uf829"

    onEnabledChanged: {
        if (enabled) {
            animateDelay.restart()
        } else {
            animateDelay.stop()
        }
    }
}
