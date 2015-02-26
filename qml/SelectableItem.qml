import QtQuick 2.4

Swipeable {
    id: root

    implicitHeight: theme.heights.large

    TextItem { anchors { fill: parent } }

    onAction: {
        var tmpIndex = index;
        itemModel.toggleSelected(index)
        resetX(tmpIndex == index ? 0 : theme.time.medium)
    }
}
