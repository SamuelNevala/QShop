import QtQuick
import QtTest
import QDynamics
import QShopper

Item {
    width: 480
    height: 720
    Dimensions { id: testDimensions }
    Component {
        id: shopComponent
        ShopView { width: 480; height: 720; dimensions: testDimensions }
    }
    TestCase {
        name: "ShoppingInteractions"
        when: windowShown
        property var shop

        function init() {
            uiSetup.resetDatabase()
            ThemeManager.activeList = "default"
            shop = createTemporaryObject(shopComponent, parent)
            verify(shop !== null)
            tryCompare(shop, "editMode", true)
            shop.forceLayout()
        }
        function editor() {
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(shop.model.editorIndex) !== null })
            const chooser = shop.itemAtIndex(shop.model.editorIndex)
            tryCompare(chooser, "x", 0)
            return chooser.item
        }
        function add(text) {
            const field = editor().contentItem
            mouseClick(field, field.width / 2, field.height / 2)
            field.forceActiveFocus()
            for (let i = 0; i < text.length; ++i)
                keyClick(text.toUpperCase().charCodeAt(i))
            compare(field.text, text)
            keyClick(Qt.Key_Return)
            tryCompare(field, "text", "")
            shop.forceLayout()
        }
        function row(index) {
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(index) !== null })
            const chooser = shop.itemAtIndex(index)
            tryCompare(chooser, "x", 0)
            const item = chooser.item
            tryCompare(item, "x", 0)
            return item
        }
        function test_empty_list_starts_in_edit_mode() {
            compare(shop.count, 1)
            compare(shop.model.editorIndex, 0)
            compare(editor().contentItem.placeholderText, "Tap to add items")
        }
        function test_enter_adds_item_and_clears_input() {
            add("milk")
            compare(shop.count, 2)
            compare(row(0).name, "milk")
        }
        function test_empty_enter_does_not_add() {
            editor().contentItem.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(shop.count, 1)
        }
        function test_leave_edit_mode_preserves_items() {
            add("milk")
            shop.setEditMode(false)
            tryCompare(shop, "count", 1)
            compare(row(0).name, "milk")
            shop.setEditMode(true)
            tryCompare(shop, "count", 2)
        }
        function test_swipe_checks_item_in_shopping_mode() {
            add("milk")
            shop.setEditMode(false)
            const item = row(0)
            tryCompare(shop.itemAtIndex(0), "y", 0)
            waitForRendering(item)
            const point = item.mapToItem(shop, item.width * 0.8, item.height / 2)
            mousePress(shop, point.x, point.y)
            mouseMove(shop, point.x - shop.width * 0.15, point.y, 30)
            mouseMove(shop, point.x - shop.width * 0.4, point.y, 30)
            mouseMove(shop, point.x - shop.width * 0.7, point.y, 30)
            mouseRelease(shop, point.x - shop.width * 0.7, point.y)
            tryCompare(item, "checked", true, 4000)
            shop.reset()
            tryCompare(item, "checked", false)
        }
        function test_bulk_removal_and_undo_restore_items() {
            add("milk")
            add("bread")
            shop.removeAll()
            tryCompare(shop, "count", 1)
            verify(editor().canUndo)
            editor().undo()
            tryCompare(shop, "count", 3)
            compare(row(1).name, "milk")
            compare(row(2).name, "bread")
        }
        function test_menu_request_from_editor() {
            const input = editor()
            const spy = createTemporaryObject(spyComponent, parent, { target: shop, signalName: "openMenu" })
            verify(spy.valid)
            mouseClick(input.contentItem, input.height / 2, input.height / 2)
            tryCompare(spy, "count", 1)
        }
    }
    Component { id: spyComponent; SignalSpy {} }
}
