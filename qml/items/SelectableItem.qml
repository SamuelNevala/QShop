import QtQuick 2.3

Swipeable {
    id: root

    height: constants.maxHeight

    TextItem {
        id: text
        height: parent.height
        width: parent.width
    }

    onAction: {
        var tmpIndex = index;
        itemModel.toggleSelected(index)
        if (tmpIndex == index) resetX()
    }
}
