import QtQuick

TextIcon {
    id: root

    property alias arrow: arrowIcon
    property alias animation: arrowAnimation
    property real ratio

    function animate() {
        if (arrowAnimation.animated) {
            return;
        }
        arrowAnimation.animated = true;
        arrowAnimation.start();
    }

    function reset() {
        if (!arrowAnimation.animated) {
            return;
        }
        arrowAnimation.animated = false;
        arrow.y = arrowAnimation.from;
    }

    clip: true
    // Red/green feedback stays bright; preserve the icon silhouette in either theme.
    color: "black"
    text: "\uf10a"

    onRatioChanged: {
        if (ratio === 0) {
            reset();
        }
        if (ratio > 1.0) {
            animate();
        }
    }

    TextIcon {
        id: arrowIcon

        color: "white"
        style: Text.Outline
        styleColor: root.color
        height: parent.height * 0.35
        width: parent.width
        leftPadding: width * 0.32
        rightPadding: width * 0.32
        text: "\uf063"
        y: arrowAnimation.from

        font {
            family: root.font.family
        }

        NumberAnimation {
            id: arrowAnimation

            property bool animated: false

            alwaysRunToEnd: true
            duration: 800
            from: -arrowIcon.height
            to: root.height / 3
            property: "y"
            target: arrowIcon

            easing {
                type: Easing.OutBack
            }
        }
    }
}
