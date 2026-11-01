import QtQuick
import QtTest
import QShopper

Item {
    width: 600
    height: 900
    TestCase {
        name: "BackNavigation"
        when: windowShown
        property var app
        property var view
        property var shop
        property var shortcut

        function init() {
            uiSetup.resetDatabase()
            Theme.activeList = "default"
            Theme.scale = 1
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml")
            compare(component.status, Component.Ready, component.errorString())
            app = createTemporaryObject(component, null, { asynchronous: false })
            verify(app !== null)
            tryCompare(app, "visible", true)
            app.requestActivate()
            tryCompare(app, "active", true)
            view = app.contentItem.children[0].item
            shop = view.contentItem
            shop.model.insert(0, "milk")
            shop.model.insert(1, "bread")
            shortcut = findChild(view, "androidBackShortcut")
            if (shortcut !== null) {
                compare(shortcut.enabled, Qt.platform.os === "android")
                // Exercise the real Back key route on Windows, changing only its platform gate.
                shortcut.enabled = Qt.binding(function() { return view.backNavigationActive })
                const popupShortcut = findChild(view, "drawerBackShortcut")
                verify(popupShortcut !== null)
                const menu = drawer()
                popupShortcut.enabled = Qt.binding(function() { return menu.visible })
            }
            Qt.inputMethod.hide()
            tryCompare(Qt.inputMethod, "visible", false)
        }

        function cleanup() {
            Qt.inputMethod.hide()
            if (app) {
                app.close()
                app.destroy()
            }
            wait(0)
        }

        function editor() {
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(shop.model.editorIndex) !== null })
            return shop.itemAtIndex(shop.model.editorIndex).item.contentItem
        }

        function drawer() {
            for (const child of shop.data) {
                if (typeof child.open === "function" && child.contentItem)
                    return child
            }
            fail("Drawer was not found")
        }

        function verifySavedItems() {
            shop.forceLayout()
            compare(shop.count, 2)
            tryVerify(function() { return shop.itemAtIndex(0) !== null && shop.itemAtIndex(1) !== null })
            compare(shop.itemAtIndex(0).name, "milk")
            compare(shop.itemAtIndex(1).name, "bread")
        }

        function test_back_closes_drawer_without_leaving_edit() {
            shop.openMenu()
            const menu = drawer()
            tryCompare(menu, "opened", true)
            keyClick(Qt.Key_Back)
            tryCompare(menu, "visible", false)
            compare(shop.editMode, true)
            compare(shop.count, 3)
            verify(app.visible)
        }

        function test_back_closes_selector_before_drawer_data() {
            return [
                { tag: "lists", index: 0 },
                { tag: "accent", index: 3 },
                { tag: "primary", index: 4 }
            ]
        }

        function openSelector(index) {
            editor().text = "unfinished"
            shop.openMenu()
            const menu = drawer()
            tryCompare(menu, "opened", true)
            const content = menu.contentItem
            content.positionViewAtIndex(index, ListView.Contain)
            content.forceLayout()
            tryVerify(function() { return content.itemAtIndex(index) !== null })
            const combo = content.itemAtIndex(index)
            mouseClick(combo, combo.width / 2, combo.height * 0.7)
            tryCompare(combo.popup, "opened", true)
            return combo
        }

        function test_back_closes_selector_before_drawer(data) {
            const combo = openSelector(data.index)
            const selected = combo.currentValue
            const menu = drawer()
            keyClick(Qt.Key_Back)
            tryCompare(combo.popup, "visible", false)
            compare(menu.opened, true)
            compare(combo.currentValue, selected)
            compare(shop.editMode, true)
            compare(editor().text, "unfinished")
            keyClick(Qt.Key_Back)
            tryCompare(menu, "visible", false)
            compare(shop.editMode, true)
            compare(editor().text, "unfinished")
            keyClick(Qt.Key_Back)
            tryCompare(shop, "editMode", false)
            verifySavedItems()
        }

        function test_selector_outside_touch_data() {
            return [
                { tag: "lists_cancel", index: 0, cancel: true },
                { tag: "accent_cancel", index: 3, cancel: true },
                { tag: "primary_cancel", index: 4, cancel: true },
                { tag: "lists_release", index: 0, cancel: false },
                { tag: "accent_release", index: 3, cancel: false },
                { tag: "primary_release", index: 4, cancel: false }
            ]
        }

        function test_selector_outside_touch(data) {
            const combo = openSelector(data.index)
            const menu = drawer()
            const selected = combo.currentValue
            // The system Back gesture starts outside the popup at the window edge.
            const surface = app.contentItem
            const y = surface.height / 3
            const touch = touchEvent(surface)
            touch.press(0, surface, 1, y).commit()
            try {
                compare(combo.popup.opened, true)
                if (data.cancel) {
                    verify(uiSetup.cancelTouch())
                    compare(combo.popup.opened, true)
                }
            } finally {
                touch.release(0, surface, 1, y).commit()
            }
            if (!data.cancel) {
                tryCompare(combo.popup, "visible", false)
            }
            compare(menu.opened, true)
            compare(combo.currentValue, selected)
            compare(editor().text, "unfinished")
            compare(shop.editMode, true)
        }

        function test_back_leaves_edit_without_focus_or_submitting_draft() {
            editor().text = "unfinished"
            view.forceActiveFocus()
            keyClick(Qt.Key_Back)
            tryCompare(shop, "editMode", false)
            verifySavedItems()
            verify(app.visible)
            shop.setEditMode(true)
            compare(editor().text, "")
        }

        function test_back_cancels_pending_item_edit() {
            const original = shop.model.editItem(0)
            compare(original, "milk")
            editor().text = "unfinished replacement"
            view.forceActiveFocus()
            keyClick(Qt.Key_Back)
            tryCompare(shop, "editMode", false)
            verifySavedItems()
        }

        function test_shopping_back_is_left_to_android() {
            shop.setEditMode(false)
            verify(shortcut !== null)
            tryCompare(shortcut, "enabled", false)
            keyClick(Qt.Key_Back)
            verifySavedItems()
            compare(shop.editMode, false)
        }

        function test_back_during_long_press_restores_row_parent() {
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(0) !== null })
            const chooser = shop.itemAtIndex(0)
            tryCompare(chooser, "x", 0)
            const item = chooser.item
            const originalParent = item.parent
            const point = item.mapToItem(shop, item.width / 2, item.height / 2)
            mousePress(shop, point.x, point.y)
            try {
                tryCompare(item, "state", "drag", 2000)
                keyClick(Qt.Key_Back)
                tryCompare(shop, "editMode", false)
                tryCompare(item, "state", "")
                tryVerify(function() { return item.parent === originalParent })
            } finally {
                mouseRelease(shop, point.x, point.y)
            }
            verifySavedItems()
        }

        function test_deliberate_long_press_reordering_still_works() {
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(0) !== null && shop.itemAtIndex(1) !== null })
            const chooser = shop.itemAtIndex(0)
            tryCompare(chooser, "x", 0)
            const item = chooser.item
            const point = item.mapToItem(shop, item.width / 2, item.height / 2)
            mousePress(shop, point.x, point.y)
            try {
                tryCompare(item, "state", "drag", 2000)
                mouseMove(shop, point.x, point.y + chooser.height, 50)
                compare(item.state, "drag")
            } finally {
                mouseRelease(shop, point.x, point.y + chooser.height)
            }
            tryCompare(item, "state", "")
            tryVerify(function() { return item.parent !== shop })
        }
    }
}
