pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material

ListView {
    id: shopView

    property string fontFamily
    property bool editMode: false
    property Item movingEditor: null
    property bool deletingBySwipe: false

    signal openMenu

    function setEditMode(mode) {
        if (editMode === mode) {
            return;
        }
        editMode = mode;
        movingEditor = null;
        if (editMode) {
            itemModel.addEditor();
            return;
        }
        itemModel.removeEditor();
    }

    function reset() {
        itemModel.reset();
    }

    function removeChecked() {
        itemModel.removeChecked();
    }

    function removeAll() {
        itemModel.removeAll();
    }

    function revealEditor() {
        if (enabled && editMode && InputMethod.visible && itemModel.editorIndex >= 0) {
            positionViewAtIndex(itemModel.editorIndex, ListView.Contain);
        }
    }

    cacheBuffer: Theme.pixels(9.27) * 40
    // The current delegate survives scrolling beyond cacheBuffer. Retain only
    // the editor so its draft, focus and IME survive while other rows are released.
    currentIndex: itemModel.editorIndex
    highlightFollowsCurrentItem: false
    keyNavigationEnabled: false
    clip: true

    delegate: DelegateChoser {
        id: chooser

        required property bool checked
        required property bool editor
        required property int index
        required property string name
        required property string displayName
        property bool moving: false

        input: editor
        height: Theme.pixels(9.27)
        width: shopView.width

        textDelegate: TextDelegate {
            checked: chooser.checked
            dragParent: shopView
            editMode: shopView.editMode
            index: chooser.index
            name: chooser.displayName

            onDoubleTapped: {
                if (!shopView.editMode) {
                    return;
                }
                const input = ((shopView.itemAtIndex(
                                    itemModel.editorIndex) as DelegateChoser).item as InputDelegate);
                input.insert(itemModel.editItem(index));
            }
            onSingleTapped: {
                if (checked) {
                    return;
                }
                const previousIndex = itemModel.editorIndex;
                const editor = shopView.itemAtIndex(previousIndex);
                itemModel.moveEditor(index);
                if (itemModel.editorIndex !== previousIndex) {
                    shopView.movingEditor = editor;
                }
            }
            onSwipeStarted: function (direction) {
                if (itemModel.readOnly) {
                    return;
                }
                if (!shopView.editMode || direction === SwipeHandler.Direction.Right) {
                    Haptics.play(Haptics.Confirm);
                } else {
                    Haptics.play(checked ? Haptics.ToggleOff : Haptics.ToggleOn);
                }
            }
            onPickedUp: {
                if (!itemModel.readOnly) {
                    Haptics.play(Haptics.DragStart);
                }
            }
            onDropped: {
                if (!itemModel.readOnly) {
                    Haptics.play(Haptics.GestureEnd);
                }
            }
            onReordered: {
                if (!itemModel.readOnly) {
                    Haptics.play(Haptics.SegmentTick);
                }
            }
            onSwiped: function (direction) {
                if (shopView.editMode && direction === SwipeHandler.Direction.Right) {
                    shopView.deletingBySwipe = true;
                    try {
                        itemModel.remove(index);
                    } finally {
                        shopView.deletingBySwipe = false;
                    }
                } else {
                    itemModel.toggleChecked(index);
                }
            }

            font {
                family: shopView.fontFamily
            }
        }
        inputDelegate: InputDelegate {
            index: chooser.index

            onAddItem: function (text) {
                itemModel.insert(index, text);
                shopView.positionViewAtIndex(index, ListView.Contain);
            }
            onBarsTapped: shopView.openMenu()

            font {
                family: shopView.fontFamily
            }
        }

        onMovingChanged: {
            if (!moving && editor && shopView.movingEditor === chooser) {
                shopView.movingEditor = null;
                Haptics.play(Haptics.GestureEnd);
            }
        }

        dropArea {
            enabled: !chooser.checked && shopView.editMode

            onEntered: function (drag) {
                itemModel.move((drag.source as Delegate).index, chooser.index);
            }
        }
    }
    model: Model {
        id: itemModel

        activeList: Theme.activeList

        onDeletionRecorded: {
            if (!shopView.deletingBySwipe) {
                Haptics.play(Haptics.Confirm);
            }
        }
        Component.onCompleted: {
            // Persist the resolved UUID instead of the initial default-list alias.
            if (Theme.activeList === "default") {
                Theme.activeList = itemModel.activeList;
            }
            shopView.setEditMode(!itemModel.count);
        }
    }
    add: Transition {
        SequentialAnimation {
            PropertyAction {
                property: "x"
                value: -shopView.width
            }

            PauseAnimation {
                duration: 250
            }

            ParallelAnimation {
                DefaultAnimation {
                    properties: "x"
                    to: 0
                }

                DefaultAnimation {
                    properties: "opacity"
                    from: 0.5
                    to: 1.0
                }
            }
        }
    }
    remove: Transition {
        SequentialAnimation {
            ParallelAnimation {
                DefaultAnimation {
                    properties: "x"
                    from: 0
                    to: shopView.width
                }

                DefaultAnimation {
                    properties: "opacity"
                    from: 1.0
                    to: 0.5
                }
            }

            SequentialAnimation {
                PropertyAction {
                    property: "ListView.delayRemove"
                    value: true
                }

                PauseAnimation {
                    duration: 250
                }

                PropertyAction {
                    property: "ListView.delayRemove"
                    value: false
                }
            }
        }
    }
    displaced: Transition {
        DefaultAnimation {
            properties: "y"
        }
    }
    removeDisplaced: Transition {
        SequentialAnimation {
            PauseAnimation {
                duration: 250
            }

            DefaultAnimation {
                properties: "y"
            }
        }
    }
    move: Transition {
        id: move

        property bool editor: ViewTransition.index == itemModel.editorIndex

        SequentialAnimation {
            PropertyAction {
                property: "moving"
                value: true
            }

            SmoothedAnimation {
                properties: "y"
                velocity: 400
                duration: move.editor ? 500 : 0
            }

            DefaultAnimation {
                properties: "y"
                duration: move.editor ? 0 : 250
            }

            PropertyAction {
                property: "moving"
                value: false
            }
        }
    }

    onHeightChanged: Qt.callLater(revealEditor)

    Connections {
        function onVisibleChanged() {
            Qt.callLater(shopView.revealEditor);
        }

        target: InputMethod
    }

    Connections {
        function onLocaleNameChanged() {
            itemModel.refreshDisplayNames();
        }

        target: AppLanguage
    }

    Pulley {
        bottomPadding: Theme.pixels(1)
        editMode: shopView.editMode
        topPadding: -parent.contentY + parent.originY - weekdays.height

        onAction: shopView.setEditMode(!shopView.editMode)

        anchors {
            left: parent.left
            right: parent.right
            bottom: weekdays.top
        }

        font {
            family: shopView.fontFamily
        }
    }

    Weekdays {
        id: weekdays

        y: -parent.contentY - height + parent.originY

        anchors {
            right: parent.right
            left: parent.left
        }
    }

    Rectangle {
        objectName: "emptyAreaBackground"
        color: Material.backgroundColor
        height: Math.max(0, shopView.height - y)
        width: shopView.width
        opacity: height <= 0 ? 0.0 : 0.8
        // Delegate bounds cover only the instantiated rows, not the whole list.
        y: Math.max(0, shopView.originY + shopView.contentHeight - shopView.contentY)
        z: -1
    }
}
