"""Render the installed launcher icon using native Android resources (API 33+).

Targets only an isolated emulator; requires JDK 21, Android SDK 36 and Pillow.
Does not launch QShopper or access its data. Saves a Settings icon screenshot too.
"""

import argparse
from io import BytesIO
import json
import os
from pathlib import Path
import re
import subprocess
import time
import uuid

from PIL import Image, ImageChops


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", type=Path, default=Path("C:/android/sdk"))
    parser.add_argument("--java", type=Path, default=Path("C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot"))
    parser.add_argument("--serial", default="emulator-5580")
    parser.add_argument("--output", type=Path, default=Path("out/android-icon"))
    args = parser.parse_args()
    assert re.fullmatch(r"emulator-\d+", args.serial), "Only an isolated emulator is allowed"
    args.output.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).with_name("IconProbe.java")
    android_jar = args.sdk / "platforms/android-36/android.jar"
    subprocess.run([str(args.java / "bin/javac.exe"), "--release", "8", "-Xlint:-options",
                    "-cp", str(android_jar), "-d", str(args.output), str(source)], check=True)
    jar = args.output / "icon.jar"
    env = dict(os.environ, JAVA_HOME=str(args.java))
    subprocess.run([str(args.sdk / "build-tools/37.0.0/d8.bat"), "--lib", str(android_jar),
                    "--min-api", "33", "--output", str(jar), str(args.output / "IconProbe.class")],
                   env=env, check=True)

    def adb(*command):
        return subprocess.check_output([str(args.sdk / "platform-tools/adb.exe"), "-s", args.serial,
                                        *map(str, command)], timeout=45)

    assert adb("shell", "getprop", "ro.kernel.qemu").strip() == b"1"
    remote = "/data/local/tmp/qshopper-icon-" + uuid.uuid4().hex
    try:
        adb("shell", "mkdir", remote)
        adb("push", jar, remote + "/icon.jar")
        output = adb("shell", "env", "CLASSPATH=" + remote + "/icon.jar", "app_process", "/system/bin",
                     "IconProbe", remote).decode()
        (args.output / "native.txt").write_text(output)
        cmake = (source.resolve().parents[2] / "CMakeLists.txt").read_text()
        version = re.search(r"project\(QShopper VERSION ([0-9.]+)", cmake).group(1)
        code = re.search(r"set\(QSHOPPER_ANDROID_VERSION_CODE (\d+)\)", cmake).group(1)
        assert f"VERSION {version} {code}" in output, output
        for name in ("adaptive", "foreground", "background", "monochrome"):
            adb("pull", remote + f"/{name}.png", args.output / f"{name}.png")
        adaptive = Image.open(args.output / "adaptive.png").convert("RGBA")
        assert adaptive.getpixel((0, 0))[3] == 0, "Adaptive mask did not clip corners"
        assert (18, 18, 18, 255) in {color for count, color in adaptive.getcolors(512 * 512)}, "Native page/pen missing"
        background = Image.open(args.output / "background.png").convert("RGBA")
        assert background.getextrema() == ((105, 105), (240, 240), (174, 174), (255, 255)), "Wrong native accent background"
        foreground = Image.open(args.output / "foreground.png").convert("RGBA")
        painted = [(x, y) for y in range(512) for x in range(512)
                   if foreground.getpixel((x, y))[3] > 128]
        assert len(painted) > 512 * 512 * .04, "Foreground too small"
        assert max(((x - 256) ** 2 + (y - 256) ** 2) ** .5 for x, y in painted) < 512 * 33 / 108
        monochrome = Image.open(args.output / "monochrome.png").convert("RGBA")
        # Native Skia edge coverage differs slightly for black and white paints.
        # Compare silhouettes at half coverage, allowing less than 0.1% edge pixels.
        foreground_mask = foreground.getchannel("A").point(lambda a: 255 if a > 128 else 0)
        monochrome_mask = monochrome.getchannel("A").point(lambda a: 255 if a > 128 else 0)
        assert foreground_mask.getbbox() == monochrome_mask.getbbox()
        assert sum(ImageChops.difference(foreground_mask, monochrome_mask).histogram()[1:]) < 512 * 512 * .001
        assert all(color[:3] == (255, 255, 255) for count, color in monochrome.getcolors(512 * 512) if color[3] == 255)
        adb("shell", "am", "start", "-a", "android.settings.APPLICATION_DETAILS_SETTINGS",
            "-d", "package:shopper.nevala.com")
        time.sleep(1)
        Image.open(BytesIO(adb("exec-out", "screencap", "-p"))).save(args.output / "settings.png")
        (args.output / "results.json").write_text(json.dumps(dict(passed=True, version=version,
            code=int(code), checks=["native adaptive mask", "foreground safe circle", "accent background",
                                   "monochrome alpha", "installed version"]), indent=2))
        print("PASS installed Android launcher resources and version " + version + " (" + code + ")")
    finally:
        adb("shell", "input", "keyevent", "KEYCODE_HOME")
        assert re.fullmatch(r"/data/local/tmp/qshopper-icon-[0-9a-f]{32}", remote)
        adb("shell", "rm", "-rf", remote)


if __name__ == "__main__":
    main()
