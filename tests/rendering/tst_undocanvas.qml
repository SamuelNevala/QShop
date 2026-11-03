pragma ComponentBehavior: Bound

import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 640
    height: 480
    Material.theme: Theme.theme

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Component {
        id: iconComponent

        UndoIcon {
            width: Theme.pixels(9.27)
            height: width
            opacity: 1
        }
    }

    Component {
        id: inputComponent

        InputDelegate {
            implicitWidth: Theme.pixels(76.6)
            width: Theme.pixels(76.6)
            height: Theme.pixels(9.27)
            canUndo: true
        }
    }

    SignalSpy {
        id: paintSpy

        signalName: "painted"
    }

    TestCase {
        function init() {
            failOnWarning(/.*/);
            Theme.scale = 1;
            Theme.theme = Material.Light;
        }

        function cleanup() {
            paintSpy.target = null;
            Theme.scale = 1;
            Theme.theme = Material.System;
        }

        function canvasFor(icon) {
            for (const child of icon.background.children) {
                if (typeof child.delay === "number" && typeof child.requestPaint === "function") {
                    return child;
                }
            }
            fail("Undo drawing item missing");
        }

        function undoFor(item) {
            if (item instanceof UndoIcon) {
                return item;
            }
            for (const child of item.children) {
                const found = undoFor(child);
                if (found) {
                    return found;
                }
            }
            return null;
        }

        function render(icon, canvas, delay) {
            paintSpy.target = canvas;
            paintSpy.clear();
            canvas.delay = delay;
            canvas.requestPaint();
            tryVerify(function () {
                return paintSpy.count > 0;
            });
            wait(50);
            return grabImage(icon);
        }

        // Sample the ring, excluding the center glyph. Neighborhoods tolerate
        // antialiasing and subpixel geometry without accepting an absent arc.
        function arcSamples(image, empty, canvas, icon) {
            let painted = 0;
            const origin = canvas.mapToItem(icon, 0, 0);
            const color = icon.color;
            for (let step = 0; step < 36; ++step) {
                const angle = canvas.startAngle + (step + 0.5) * Math.PI / 18;
                const x = Math.round(origin.x + canvas.arcX + canvas.radius * Math.cos(angle));
                const y = Math.round(origin.y + canvas.arcX + canvas.radius * Math.sin(angle));
                let found = false;
                for (let dx = -1; dx <= 1; ++dx) {
                    for (let dy = -1; dy <= 1; ++dy) {
                        const pixel = image.pixel(x + dx, y + dy);
                        const background = empty.pixel(x + dx, y + dy);
                        const red = color.r * color.a + background.r * (1 - color.a);
                        const green = color.g * color.a + background.g * (1 - color.a);
                        const blue = color.b * color.a + background.b * (1 - color.a);
                        if (Math.abs(pixel.r - red) < 0.18 && Math.abs(pixel.g - green) < 0.18
                                && Math.abs(pixel.b - blue) < 0.18) {
                            found = true;
                        }
                    }
                }
                if (found) {
                    ++painted;
                }
            }
            return painted;
        }

        function test_arc_data() {
            return [
                        {
                            tag: "light-1",
                            theme: Material.Light,
                            scale: 1
                        },
                        {
                            tag: "dark-1",
                            theme: Material.Dark,
                            scale: 1
                        },
                        {
                            tag: "light-2",
                            theme: Material.Light,
                            scale: 2
                        },
                        {
                            tag: "dark-2",
                            theme: Material.Dark,
                            scale: 2
                        }
                    ];
        }

        function test_arc(data) {
            Theme.theme = data.theme;
            Theme.scale = data.scale;
            const icon = createTemporaryObject(iconComponent, scene, {
                                                   enabled: false
                                               });
            verify(icon !== null);
            const canvas = canvasFor(icon);
            tryCompare(canvas, "available", true);
            fuzzyCompare(canvas.lineWidth, Theme.pixels(0.5), 0.001);
            fuzzyCompare(canvas.width, icon.background.width - Theme.pixels(0.4), 0.001);
            for (const width of [9.27, 12]) {
                icon.width = Theme.pixels(width);
                wait(50);
                const empty = render(icon, canvas, 0);
                const backgroundPoint = icon.background.mapToItem(icon, icon.background.width / 2,
                                                                  icon.background.height * 0.2);
                const backgroundPixel = empty.pixel(Math.round(backgroundPoint.x), Math.round(
                                                        backgroundPoint.y));
                fuzzyCompare(backgroundPixel.r, icon.background.color.r, 0.02);
                fuzzyCompare(backgroundPixel.g, icon.background.color.g, 0.02);
                fuzzyCompare(backgroundPixel.b, icon.background.color.b, 0.02);
                for (const delay of [1, 0.5, 0]) {
                    const image = render(icon, canvas, delay);
                    const samples = arcSamples(image, empty, canvas, icon);
                    verify(Math.abs(samples - delay * 32.4) <= 3, "arc samples=" + samples + " delay=" + delay
                           + " width=" + width);
                    // The stroke stays inside the canvas at all tested sizes.
                    compare(image.pixel(0, Math.floor(image.height / 2)), empty.pixel(0, Math.floor(
                                                                                          empty.height
                                                                                          / 2)));
                }
            }
        }

        function test_enable_stop_restart() {
            const icon = createTemporaryObject(iconComponent, scene, {
                                                   enabled: false
                                               });
            const canvas = canvasFor(icon);
            icon.enabled = true;
            tryVerify(function () {
                return canvas.delay < 0.98;
            }, 1500);
            icon.enabled = false;
            const stopped = canvas.delay;
            wait(200);
            compare(canvas.delay, stopped);
            icon.enabled = true;
            verify(canvas.delay > stopped);
            tryVerify(function () {
                return canvas.delay < 0.99;
            }, 1500);
        }

        function test_initial_enabled_caller() {
            const standalone = createTemporaryObject(iconComponent, scene, {
                                                         enabled: true
                                                     });
            const input = createTemporaryObject(inputComponent, scene);
            verify(input !== null);
            const undo = undoFor(input);
            verify(undo !== null);
            compare(undo.enabled, true);
            tryVerify(function () {
                return canvasFor(undo).delay < 0.99;
            }, 1500);
            compare(canvasFor(standalone).delay, 1);
        }

        name: "UndoCanvas"
        when: windowShown
    }
}
