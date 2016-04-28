import QtQuick 2.6
import Shop.models 1.0

ListView {
    id: mainView

    function setEditMode(mode)
    {
        if (editMode === mode) return
        editMode = mode
        if (editMode)
            itemModel.addEditor()
        else {
            itemModel.removeEditor()
            focusHolder.forceActiveFocus()
        }
    }

    property bool editMode: false
    property int deleteIndex: -1

    Pulley {
        actionText: editMode ? qsTr("Release to shop") : qsTr("Release to edit")
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: -parent.contentY + parent.originY - weekdays.height
        pullHint: editMode ? qsTr("Pull to shop") : qsTr("Pull to edit")
        onAction: setEditMode(!editMode)
    }

    Weekdays {
        id: weekdays
        anchors { right: parent.right; left: parent.left }
        y: -parent.contentY - height + parent.originY - mainView.anchors.topMargin
    }

    Rectangle {
        color: "black"
        height: Math.max(mainView.height - mainView.contentHeight, 0)
        opacity: visible ? 0.8 : 0.0
        visible: height; width:  mainView.width
        y: -mainView.contentY + mainView.contentHeight; z: -1
    }

    cacheBuffer: theme.heights.large * 40
    currentIndex: -1
    clip: applicationWindow.remorse
    delegate: Component {
        Loader {
            property bool isEditor: editor
            width: parent.width
            source: editor ? Qt.resolvedUrl("InputItem.qml")
                           : editMode ? Qt.resolvedUrl("DragableItem.qml")
                                      : Qt.resolvedUrl("SelectableItem.qml")
        }
    }

    add: Transition {
        ParallelAnimation {
            DefaultAnimation { properties: "x"; from: -mainView.width; to: 0 }
            DefaultAnimation { properties: "opacity"; from: 0.5; to: 1.0 }
        }
    }

    remove: Transition {
        ParallelAnimation {
            DefaultAnimation { properties: "x"; from: 0; to: mainView.width }
            DefaultAnimation { properties: "opacity"; from: 1.0; to: 0.5 }
        }
    }

    displaced: Transition {
        DefaultAnimation { properties: "y" }
    }

    removeDisplaced: Transition {
        SequentialAnimation {
            PauseAnimation { duration: theme.time.medium }
            DefaultAnimation { properties: "y" }
        }
    }

    move: Transition {
        id: moveTransition
        DefaultAnimation { properties: "y"; duration: moveTransition.ViewTransition.item.isEditor ? 0 : theme.time.medium }
        SmoothedAnimation { properties: "y"; velocity: 400; duration: moveTransition.ViewTransition.item.isEditor ? 800 : 0 }
    }

    onHeightChanged: {
        if (!editMode || applicationWindow.remorse ) {
            return
        }
        positionViewAtIndex(itemModel.editorIndex, ListView.Contain)
    }
}
