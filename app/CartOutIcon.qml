import QtQuick

ArrowIcon {
    id: root

    text: "\uf07a"

    animation {
        from: root.height / 8
        to: -arrow.height

        easing {
            type: Easing.InBack
        }
    }

    arrow {
        text: "\uf062"
    }
}
