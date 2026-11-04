import QtQuick

ArrowIcon {
    id: root

    text: "\uf07a"

    animation {
        from: root.height / 4
        to: -arrow.height

        easing {
            type: Easing.InBack
        }
    }

    arrow {
        leftPadding: arrow.width * 0.42
        rightPadding: arrow.width * 0.23
        text: "\uf062"
    }
}
