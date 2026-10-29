import QtQuick
import QtTest
import QShopper

Item {
    id: scene
    width: 800
    height: 900
    Binding { target: Theme; property: "parent"; value: scene }
    Component {
        id: viewComponent
        View { width: Theme.pixels(76.6); height: Theme.pixels(162.8) }
    }

    TestCase {
        name: "SwipeSensitivity"
        when: windowShown
        property var view
        property var shop

        function init() {
            uiSetup.resetDatabase()
            Theme.scale = 1
            Theme.swipeSensitivity = 1
            Theme.activeList = "default"
            view = createTemporaryObject(viewComponent, scene)
            verify(view !== null)
            shop = view.contentItem
            shop.model.insert(0, "milk")
            shop.model.insert(1, "bread")
            shop.setEditMode(false)
        }

        function cleanup() { Theme.swipeSensitivity = 1 }

        function row() {
            shop.forceLayout()
            const index = shop.editMode ? 1 : 0
            tryVerify(function() { return shop.itemAtIndex(index) !== null })
            const chooser = shop.itemAtIndex(index)
            tryCompare(chooser, "x", 0)
            tryCompare(chooser, "y", chooser.height * index)
            tryCompare(chooser.item, "x", 0)
            compare(chooser.item.name, "milk")
            return chooser.item
        }

        function swipe(item, right, millimeters, duration) {
            const start = item.mapToItem(shop, item.width * (right ? 0.15 : 0.85), item.height / 2)
            const distance = Theme.pixels(millimeters) * (right ? 1 : -1)
            verify(Math.abs(distance) < item.width / 2, "Exercise velocity without the distance fallback")
            const touch = touchEvent(shop)
            touch.press(0, shop, start.x, start.y).commit()
            touch.move(0, shop, start.x + distance / 3, start.y).commit()
            wait(duration / 2)
            touch.move(0, shop, start.x + distance * 2 / 3, start.y).commit()
            wait(duration / 2)
            touch.move(0, shop, start.x + distance, start.y).commit()
            touch.release(0, shop, start.x + distance, start.y).commit()
        }

        function test_comfortable_swipe_data() {
            return [
                { tag: "shop_left", edit: false, right: false },
                { tag: "shop_right", edit: false, right: true },
                { tag: "edit_left", edit: true, right: false },
                { tag: "edit_right", edit: true, right: true }
            ]
        }

        function test_comfortable_swipe(data) {
            shop.setEditMode(data.edit)
            const item = row()
            // About 350 mm/s over a short stroke, below the half-width mark.
            swipe(item, data.right, 25, 70)
            if (data.edit && data.right) {
                tryCompare(shop, "count", 2, 2000)
                verify(shop.model.canUndo)
            } else {
                tryCompare(item, "checked", true, 2000)
            }
        }

        function test_default_matches_phone_tested_effort() {
            // A wider row gives the timed threshold test room for event-loop jitter.
            view.width = Theme.pixels(200)
            const item = row()
            swipe(item, true, 90, 205)
            tryCompare(item, "checked", true, 2000)
        }

        function findSlider(item) {
            if (item.from === 0.2 && item.to === 3)
                return item
            for (const child of item.children) {
                const slider = findSlider(child)
                if (slider)
                    return slider
            }
            return null
        }

        function sensitivitySlider() {
            shop.openMenu()
            let drawer = null
            for (const child of shop.data) {
                if (typeof child.open === "function" && child.contentItem)
                    drawer = child
            }
            verify(drawer !== null)
            tryCompare(drawer, "opened", true)
            const list = drawer.contentItem
            list.positionViewAtIndex(5, ListView.Contain)
            list.forceLayout()
            tryVerify(function() { return list.itemAtIndex(5) !== null })
            const slider = findSlider(list.itemAtIndex(5))
            verify(slider !== null)
            return { slider: slider, drawer: drawer }
        }

        function test_slider_makes_the_same_gesture_easier() {
            const item = row()
            swipe(item, true, 10, 50)
            wait(350)
            compare(item.checked, false)
            compare(item.x, 0)
            const controls = sensitivitySlider()
            const slider = controls.slider
            mousePress(slider.handle, slider.handle.width / 2, slider.handle.height / 2)
            mouseMove(slider, slider.width - slider.rightPadding - slider.handle.width / 2, slider.height / 2, 30)
            mouseRelease(slider, slider.width - slider.rightPadding - slider.handle.width / 2, slider.height / 2)
            tryCompare(Theme, "swipeSensitivity", 3)
            controls.drawer.close()
            tryCompare(controls.drawer, "visible", false)
            swipe(item, true, 10, 50)
            tryCompare(item, "checked", true, 2000)
            tryVerify(function() { return uiSetup.savedSetting("swipeSensitivity") === 3 })
        }

        function test_opening_controls_preserves_sensitivity() {
            Theme.swipeSensitivity = 2.4
            const controls = sensitivitySlider()
            fuzzyCompare(controls.slider.value, 2.4, 0.001)
            fuzzyCompare(Theme.swipeSensitivity, 2.4, 0.001)
            controls.drawer.close()
        }

        function test_sensitivity_limits_data() {
            return [
                { tag: "low_requires_firmer_swipe", sensitivity: 0.2, distance: 25, duration: 70 },
                { tag: "high_rejects_short_slow_motion", sensitivity: 3, distance: 5, duration: 250 }
            ]
        }

        function test_sensitivity_limits(data) {
            Theme.swipeSensitivity = data.sensitivity
            const item = row()
            swipe(item, true, data.distance, data.duration)
            wait(350)
            compare(item.checked, false)
            compare(item.x, 0)
            compare(shop.count, 2)
        }
    }
}
