"""Offline regression: transport loss must fail with recorded cleanup attempts."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


source = Path(os.environ.get("QSHOPPER_MATRIX_MODULE", Path(__file__).with_name("test_displaymatrix.py")))
spec = importlib.util.spec_from_file_location("displaymatrix_under_test", source)
matrix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(matrix)


class DisplayMatrixControl(unittest.TestCase):
    def test_disconnect_records_failed_restoration_and_attempts_every_setting(self):
        commands = []
        disconnected = False
        responses = {
            ("getprop", "ro.kernel.qemu"): "1",
            ("wm", "size"): "Physical size: 1440x3120",
            ("wm", "density"): "Physical density: 560",
            ("wm", "user-rotation"): "free",
            ("settings", "get", "system", "accelerometer_rotation"): "1",
            ("getprop", "ro.build.fingerprint"): "offline-fixture",
            ("settings", "get", "secure", "default_input_method"): "fixture-ime",
            ("settings", "get", "system", "font_scale"): "1.0",
            ("pm", "path", "shopper.nevala.com"): "package:/fixture/base.apk",
            ("sha256sum", "/fixture/base.apk"): "0" * 64 + " /fixture/base.apk",
            ("am", "force-stop", "shopper.nevala.com"): "",
        }

        def output(command, **kwargs):
            nonlocal disconnected
            args = tuple(command[4:])  # adb -s serial shell ...
            commands.append(args)
            if args == ("wm", "size", "1440x3120"):
                disconnected = True
            if disconnected:
                raise subprocess.CalledProcessError(1, command, output=b"device offline")
            return responses[args].encode()

        with tempfile.TemporaryDirectory(prefix="qshopper-matrix-control-") as temporary:
            arguments = ["matrix", "--adb", "fixture-adb", "--profile", "baseline", "--output", temporary]
            with patch.object(sys, "argv", arguments), patch.object(matrix.subprocess, "check_output", output):
                with self.assertRaises(AssertionError):
                    matrix.main()
            report = json.loads((Path(temporary) / "results.json").read_text(encoding="utf-8"))
            self.assertFalse(report["restore_matches"])
            for setting in ("size", "density", "rotation", "auto"):
                self.assertIn(setting, report["restore_errors"])
            self.assertIn(("wm", "size", "reset"), commands)
            self.assertIn(("wm", "density", "reset"), commands)
            self.assertIn(("wm", "user-rotation", "free"), commands)
            self.assertIn(("settings", "put", "system", "accelerometer_rotation", "1"), commands)


if __name__ == "__main__":
    unittest.main()
