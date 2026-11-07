pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 800
    height: 500
    Material.theme: Theme.theme

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Rectangle {
        anchors.fill: parent
        color: scene.Material.backgroundColor
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.otf"
    }

    Component {
        id: spyComponent

        SignalSpy {}
    }

    Component {
        id: rowComponent

        TextDelegate {
            y: 150
            width: 720
            height: Theme.pixels(9.27)
            name: "Milk"
            font.family: icons.name
            dragParent: scene
        }
    }

    TestCase {
        id: test

        property var pointer
        property var row
        property var actions
        property point origin

        function cases() {
            const result = [];
            for (const dark of [false, true]) {
                for (const variant of ["in", "out", "trash"]) {
                    result.push({
                                    tag: (dark ? "dark-" : "light-") + variant,
                                    dark: dark,
                                    variant: variant
                                });
                }
            }
            return result;
        }

        function init() {
            failOnWarning(/.*/);
            Theme.scale = 2;
            Theme.swipeSensitivity = 0;
            tryCompare(icons, "status", FontLoader.Ready);
        }

        function cleanup() {
            if (pointer) {
                pointer.release(0, scene, origin.x, origin.y).commit();
                pointer = null;
            }
        }

        function makeRow(data) {
            Theme.theme = data.dark ? Material.Dark : Material.Light;
            row = createTemporaryObject(rowComponent, scene, {
                                            checked: data.variant === "out",
                                            editMode: data.variant === "trash"
                                        });
            verify(row !== null);
            actions = createTemporaryObject(spyComponent, scene, {
                                                target: row,
                                                signalName: "swiped"
                                            });
            wait(50);
            const loaders = row.background.children.filter(child => child instanceof IconChoser);
            return loaders[data.right === false ? 1 : 0].item;
        }

        function pull(distance) {
            origin = row.mapToItem(scene, distance < 0 ? row.width - 100 : 100, row.height / 2);
            pointer = touchEvent(scene);
            pointer.press(0, scene, origin.x, origin.y).commit();
            for (let step = 1; step <= 4; ++step) {
                pointer.move(0, scene, origin.x + distance * step / 4, origin.y).commit();
                wait(15);
            }
        }

        function returnAndRelease() {
            pointer.move(0, scene, origin.x, origin.y).commit();
            pointer.release(0, scene, origin.x, origin.y).commit();
            pointer = null;
            tryCompare(row, "x", 0, 400);
            wait(270);
        }

        function test_cart_arrow_alignment_data() {
            const result = [];
            for (const data of cases().filter(value => value.variant !== "trash")) {
                for (const right of [false, true]) {
                    for (const scale of [1, 2]) {
                        result.push(Object.assign({}, data, {
                                                      tag: data.tag + (right ? "-right-" :
                                                                               "-left-") + scale,
                                                      right: right,
                                                      scale: scale
                                                  }));
                    }
                }
            }
            return result;
        }

        function test_cart_arrow_alignment(data) {
            Theme.scale = data.scale;
            const icon = makeRow(data);
            pull(row.height * (data.right ? 1.6 : -1.6));
            if (data.variant === "in") {
                icon.animation.complete();
            } else {
                icon.reset();
            }
            // Check the actual arrival (in) and departure (out) basket position.
            tryCompare(icon, "opacity", 1, 1000);
            const visible = grabImage(scene);
            icon.arrow.visible = false;
            wait(30);
            const body = grabImage(scene);
            const bounds = icon.mapToItem(scene, Qt.rect(0, 0, icon.width, icon.height));
            const sx = body.width / scene.width;
            const sy = body.height / scene.height;
            const left = Math.ceil(bounds.x * sx);
            const right = Math.floor((bounds.x + bounds.width) * sx);
            let basketCenter = 0;
            let basketRows = 0;
            for (let y = Math.ceil((bounds.y + bounds.height * .3) * sy); y < Math.floor((bounds.y
                                                                                          + bounds.height
                                                                                          * .5) * sy); ++y) {
                let start = left;
                let bestStart = left;
                let bestWidth = 0;
                for (let x = left; x <= right; ++x) {
                    const pixel = x < right ? body.pixel(x, y) : Qt.rgba(1, 1, 1, 1);
                    if (pixel.r > .1 || pixel.g > .1 || pixel.b > .1) {
                        if (x - start > bestWidth) {
                            bestStart = start;
                            bestWidth = x - start;
                        }
                        start = x + 1;
                    }
                }
                if (bestWidth > (right - left) * .25) {
                    basketCenter += bestStart + (bestWidth - 1) / 2;
                    ++basketRows;
                }
            }
            verify(basketRows > 0, "Actual basket interior must be rendered");
            basketCenter /= basketRows;
            let arrowCenter = 0;
            let arrowPixels = 0;
            let arrowTop = visible.height;
            let arrowBottom = 0;
            for (let y = Math.ceil(bounds.y * sy); y < Math.floor((bounds.y + bounds.height)
                                                                  * sy); ++y) {
                for (let x = left; x < right; ++x) {
                    const pixel = visible.pixel(x, y);
                    if (pixel.r > .9 && pixel.g > .9 && pixel.b > .9) {
                        arrowCenter += x;
                        ++arrowPixels;
                        arrowTop = Math.min(arrowTop, y);
                        arrowBottom = Math.max(arrowBottom, y);
                    }
                }
            }
            verify(arrowPixels >= 3, "Actual arrow cores must be rendered");
            arrowCenter /= arrowPixels;
            fuzzyCompare(arrowCenter, basketCenter, Math.max(1, bounds.width * sx * .025),
                         "Arrow must be centered in the rendered basket, including mirrored swipes");


            let basketTop = 0;
            let basketBottom = 0;
            for (let y = Math.ceil((bounds.y + bounds.height * .1) * sy); y < Math.floor((bounds.y
                                                                                          + bounds.height
                                                                                          * .6) * sy); ++y) {
                const pixel = body.pixel(Math.round(basketCenter), y);
                if (pixel.r < .1 && pixel.g < .1 && pixel.b < .1) {
                    if (basketTop === 0) {
                        basketTop = y;
                    }
                    basketBottom = y;
                } else if (basketBottom > 0) {
                    break;
                }
            }
            verify(basketBottom > 0, "Actual basket floor must be rendered");
            verify(arrowBottom < basketBottom,
                   "Arrow basket position must stay above the basket floor: tip=" + arrowBottom
                   + ", floor=" + basketBottom);
            fuzzyCompare((arrowTop + arrowBottom) / 2, (basketTop + basketBottom) / 2, Math.max(1,
                                                                                                bounds.height
                                                                                                * sy * .025),
                         "The whole arrow must finish in the middle of the basket");
            icon.arrow.visible = true;
            returnAndRelease();
            compare(actions.count, 0);
        }

        function test_rapid_second_swipe_data() {
            return cases();
        }

        function test_rapid_second_swipe(data) {
            const icon = makeRow(data);
            pull(row.height * 1.6);
            wait(180);
            verify(icon.ratio > 1 && icon.opacity > .5, "x=" + row.x + " ratio=" + icon.ratio
                   + " opacity=" + icon.opacity + " height=" + row.height);

            const first = icon.arrow.y / icon.height;
            grabImage(scene).save("arrow-" + data.tag + "-first.png");
            returnAndRelease();
            pull(row.height * 1.6);
            wait(180);
            verify(icon.ratio > 1 && icon.opacity > .5, "x=" + row.x + " ratio=" + icon.ratio
                   + " opacity=" + icon.opacity + " height=" + row.height);

            grabImage(scene).save("arrow-" + data.tag + "-second.png");
            fuzzyCompare(icon.arrow.y / icon.height, first, .09,
                         "A new visible swipe must replay the same arrow trajectory");
            returnAndRelease();
            compare(actions.count, 0, "Pullback must not perform a check/delete action");
        }

        function test_resized_idle_feedback_data() {
            return cases();
        }

        function test_resized_idle_feedback(data) {
            const icon = makeRow(data);
            const starts = createTemporaryObject(spyComponent, scene, {
                                                     target: icon.animation,
                                                     signalName: "started"
                                                 });
            pull(row.height * 1.6);
            compare(starts.count, 1);
            wait(850);
            pointer.move(0, scene, origin.x + row.height * .8, origin.y).commit();
            wait(30);
            pointer.move(0, scene, origin.x + row.height * 1.6, origin.y).commit();
            wait(30);
            compare(starts.count, 1, "Recrossing without returning to zero is the same excursion");
            returnAndRelease();
            Theme.scale = 3;
            wait(50);
            pull(row.height * .8);
            wait(270);
            verify(icon.ratio > .4 && icon.ratio < 1 && icon.opacity > .4,
                   "Expose resized feedback x=" + row.x + " ratio=" + icon.ratio + " opacity="
                   + icon.opacity);
            grabImage(scene).save("arrow-" + data.tag + "-resized.png");
            fuzzyCompare(icon.arrow.y, icon.animation.from, .1,
                         "Visible pre-threshold arrow must use the current icon size");
            returnAndRelease();
            compare(actions.count, 0);
        }

        name: "ArrowFeedback"
        when: windowShown
    }
}
