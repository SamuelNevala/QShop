import QtQuick
import QtTest
import QShopper

Item {
    width: 600
    height: 900
    TestCase {
        name: "ResetChecks"
        when: windowShown
        property var app
        property var shop

        function openApp() {
            const component = Qt.createComponent("qrc:/qt/qml/QShopper/main.qml")
            compare(component.status, Component.Ready, component.errorString())
            app = createTemporaryObject(component, null, { asynchronous: false })
            verify(app !== null)
            tryCompare(app, "visible", true)
            app.requestActivate()
            tryCompare(app, "active", true)
            shop = app.contentItem.children[0].item.contentItem
        }

        function init() {
            uiSetup.resetDatabase()
            Theme.activeList = "default"
            Theme.scale = 1
            openApp()
            shop.model.insert(0, "1")
            shop.model.insert(1, "2")
            shop.model.insert(2, "3")
            shop.setEditMode(false)
            wait(600)
        }

        function cleanup() {
            if (app) {
                app.close()
                app.destroy()
            }
            wait(0)
        }

        function itemNamed(name) {
            shop.forceLayout()
            for (let index = 0; index < shop.count; ++index) {
                const chooser = shop.itemAtIndex(index)
                if (chooser && chooser.name === name) {
                    tryCompare(chooser, "x", 0)
                    tryCompare(chooser.item, "x", 0)
                    return chooser.item
                }
            }
            fail("Item was not found: " + name)
        }

        function checkItem(name) {
            const item = itemNamed(name)
            const start = item.mapToItem(shop, item.width * 0.85, item.height / 2)
            const touch = touchEvent(shop)
            touch.press(0, shop, start.x, start.y).commit()
            touch.move(0, shop, start.x - item.width * 0.2, start.y).commit()
            touch.move(0, shop, start.x - item.width * 0.4, start.y).commit()
            touch.release(0, shop, start.x - item.width * 0.7, start.y).commit()
            tryCompare(item, "checked", true)
            tryCompare(item, "x", 0)
            wait(350)
        }

        function editor() {
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(shop.model.editorIndex) !== null })
            const chooser = shop.itemAtIndex(shop.model.editorIndex)
            tryCompare(chooser, "x", 0)
            return chooser.item.contentItem
        }

        function resetButton(item) {
            if (item.text === "Reset\nchecks" && typeof item.clicked === "function") {
                return item
            }
            for (const child of item.children) {
                const found = resetButton(child)
                if (found) {
                    return found
                }
            }
            return null
        }

        function clickReset() {
            const field = editor()
            mouseClick(field, field.height / 2, field.height / 2)
            let drawer = null
            for (const child of shop.data) {
                if (typeof child.open === "function" && child.contentItem) {
                    drawer = child
                }
            }
            verify(drawer !== null)
            tryCompare(drawer, "opened", true)
            const menu = drawer.contentItem
            menu.positionViewAtIndex(1, ListView.Contain)
            menu.forceLayout()
            const button = resetButton(menu.itemAtIndex(1))
            verify(button !== null)
            mouseClick(button, button.width / 2, button.height / 2)
            tryCompare(drawer, "visible", false)
        }

        function verifyResetItems(expected) {
            tryCompare(shop, "count", expected.length)
            shop.forceLayout()
            for (let index = 0; index < expected.length; ++index) {
                const row = shop.itemAtIndex(index)
                verify(row !== null)
                compare(row.name, expected[index])
                compare(row.checked, false)
            }
        }

        function test_drawer_reset_data() {
            return [{ tag: "reported_sequence", pending: false, mixed: false },
                    { tag: "editing_first_checked_item", pending: "3", mixed: false },
                    { tag: "editing_middle_checked_item", pending: "1", mixed: false },
                    { tag: "editing_last_checked_item", pending: "2", mixed: false },
                    { tag: "mixed_list", pending: false, mixed: true }]
        }

        function test_drawer_reset(data) {
            if (data.mixed) {
                shop.model.insert(0, "A")
                shop.model.insert(1, "B")
                wait(600)
            }
            const expected = data.mixed ? ["A", "B", "3", "1", "2"] : ["3", "1", "2"]
            for (const name of ["3", "1", "2"]) {
                checkItem(name)
            }
            shop.setEditMode(true)
            wait(600)
            if (data.pending) {
                const item = itemNamed(data.pending)
                const point = item.mapToItem(shop, item.width / 2, item.height / 2)
                const touch = touchEvent(shop)
                touch.press(0, shop, point.x, point.y).commit()
                touch.release(0, shop, point.x, point.y).commit()
                wait(50)
                touch.press(0, shop, point.x, point.y).commit()
                touch.release(0, shop, point.x, point.y).commit()
                tryCompare(editor(), "text", data.pending)
            }
            clickReset()
            if (data.pending) {
                compare(editor().text, data.pending)
            }
            shop.setEditMode(false)
            verifyResetItems(expected)
            shop.setEditMode(true)
            clickReset()
            shop.setEditMode(false)
            verifyResetItems(expected)
            app.close()
            app.destroy()
            wait(0)
            openApp()
            verifyResetItems(expected)
        }
    }
}
