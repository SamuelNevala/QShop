ArrowIcon {
    id: root

    animation { to: root.height / 4 }
    arrow { leftPadding: arrow.width * 0.42; rightPadding: arrow.width * 0.23; }
    text: "\uf07a"

    WheelIcon {
        font { family: root.font.family }
        height: parent.height / 8; width: height
        x: parent.width * 0.3; y: parent.height * 0.73
    }

    WheelIcon {
        font { family: root.font.family }
        height: parent.height / 8; width: height
        x: parent.width * 0.72; y: parent.height * 0.73
    }
}
