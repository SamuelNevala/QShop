import QtQuick 2.4

Swipeable {
    id: root

    height: theme.heights.large

    TextItem {
        id: text
        height: parent.height
        width: parent.width
    }

    onAction: {
        var tmpIndex = index;
        itemModel.toggleSelected(index)
        resetX(tmpIndex == index ? 0 : constants.mediumTime )
    }
}
