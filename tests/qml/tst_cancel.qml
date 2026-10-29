import QtQuick
import QtTest
import QShopper

Item {
    width: 600
    height: 900
    Component { id: spyComponent; SignalSpy { signalName: "swiped" } }
    TestCase {
        name: "PointerCancellation"
        when: windowShown
        property var app
        property var shop

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
            shop = app.contentItem.children[0].item.contentItem
            shop.model.insert(0, "milk")
            shop.model.insert(1, "bread")
            Qt.inputMethod.hide()
        }

        function cleanup() {
            if (app) {
                app.close()
                app.destroy()
            }
            wait(0)
        }

        function tapRecognizer(item) {
            for (const child of item.data) {
                if (child instanceof Loader && child.item instanceof TapHandler) {
                    return child.item
                }
            }
            for (const child of item.data) {
                if (child instanceof TapHandler) {
                    return child
                }
            }
            return null
        }

        function test_cancel_data() {
            return [
                { tag: "before_long_press", held: false, reorder: false, swipe: false },
                { tag: "long_press", held: true, reorder: false, swipe: false },
                { tag: "active_reorder", held: true, reorder: true, swipe: false },
                { tag: "edit_right_swipe", held: false, reorder: false, swipe: true, right: true },
                { tag: "edit_left_swipe", held: false, reorder: false, swipe: true, right: false },
                { tag: "shop_right_swipe", held: false, reorder: false, swipe: true, right: true, edit: false },
                { tag: "shop_left_swipe", held: false, reorder: false, swipe: true, right: false, edit: false }
            ]
        }

        function test_cancel(data) {
            if (data.edit === false) {
                shop.setEditMode(false)
            }
            shop.forceLayout()
            tryVerify(function() { return shop.itemAtIndex(0) !== null })
            const chooser = shop.itemAtIndex(0)
            tryCompare(chooser, "x", 0)
            const item = chooser.item
            const originalParent = item.parent
            const start = item.mapToItem(shop, item.width / 2, item.height / 2)
            const spy = createTemporaryObject(spyComponent, parent, { target: item })
            verify(spy.valid)
            const touch = touchEvent(shop)
            touch.press(0, shop, start.x, start.y).commit()
            try {
                if (data.held) {
                    tryCompare(item, "state", "drag", 2000)
                }
                if (data.reorder) {
                    touch.move(0, shop, start.x, start.y + chooser.height / 3).commit()
                }
                if (data.swipe) {
                    const sign = data.right ? 1 : -1
                    touch.move(0, shop, start.x + sign * item.width * 0.1, start.y).commit()
                    touch.move(0, shop, start.x + sign * item.width * 0.2, start.y).commit()
                    touch.move(0, shop, start.x + sign * item.width * 0.3, start.y).commit()
                    tryVerify(function() { return Math.abs(item.x) > 0 })
                }
                verify(uiSetup.cancelTouch())
                // Assert recovery before sending any release or new input.
                tryVerify(function() {
                    const handler = tapRecognizer(item)
                    return handler !== null && !handler.pressed
                })
                tryCompare(item, "state", "")
                tryVerify(function() { return item.parent === originalParent })
                tryCompare(item, "x", 0)
                if (!data.held && !data.swipe) {
                    wait(1000)
                }
                compare(item.state, "")
                compare(spy.count, 0)
                compare(item.checked, false)
                compare(shop.count, shop.editMode ? 3 : 2)
            } finally {
                // Finish QtTest's synthetic sequence after checking cancellation itself.
                touch.release(0, shop, start.x, start.y).commit()
            }
            if (shop.editMode) {
                const hold = touchEvent(shop)
                hold.press(0, shop, start.x, start.y).commit()
                try {
                    tryCompare(item, "state", "drag", 2000)
                } finally {
                    hold.release(0, shop, start.x, start.y).commit()
                }
                tryCompare(item, "state", "")
            }
            const next = touchEvent(shop)
            next.press(0, shop, start.x, start.y).commit()
            next.move(0, shop, start.x - item.width * 0.2, start.y).commit()
            next.move(0, shop, start.x - item.width * 0.4, start.y).commit()
            next.release(0, shop, start.x - item.width * 0.4, start.y).commit()
            tryCompare(item, "checked", true, 2000)
        }
    }
}
