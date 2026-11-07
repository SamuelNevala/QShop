"""Offline dictation-driver cleanup regressions; no emulator or microphone."""

import importlib.util
import json
import os
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


path = Path(os.environ.get("QSHOPPER_DICTATION_MODULE", Path(__file__).with_name("test_dictation.py")))
spec = importlib.util.spec_from_file_location("dictation_driver", path)
driver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(driver)


class DictationCleanup(unittest.TestCase):
    def test_channel_creation_failure_removes_trusted_public_key(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            discovery = root / "emulator.ini"
            discovery.write_text(f"avd.id=QShopper_API_36\nport.serial=5580\ncmdline=-grpc-use-jwt\n"
                                 f"grpc.jwks={root}\ngrpc.port=8554\n")

            def unavailable(*args):
                raise RuntimeError("channel unavailable")

            modules = {"grpc": SimpleNamespace(insecure_channel=unavailable),
                       "emulator_controller_pb2": SimpleNamespace(),
                       "emulator_controller_pb2_grpc": SimpleNamespace()}
            with patch.dict("sys.modules", modules):
                with self.assertRaisesRegex(RuntimeError, "channel unavailable"):
                    driver.SyntheticAudio(discovery, root)
            self.assertEqual(list(root.glob("qshopper-*.jwk")), [])

    def test_channel_close_failure_still_removes_key(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "own-public-key.jwk"
            path.write_text("public test fixture")
            audio = object.__new__(driver.SyntheticAudio)
            audio.path = path

            def broken_close():
                raise RuntimeError("channel close failed")

            audio.channel = SimpleNamespace(close=broken_close)
            with self.assertRaisesRegex(RuntimeError, "channel close failed"):
                audio.close()
            self.assertFalse(path.exists())

    def test_disconnected_cleanup_attempts_every_resource_and_reports_errors(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            fixture = root / "synthetic.wav"
            fixture.write_bytes(b"unused: fails before audio injection")
            args = SimpleNamespace(adb="adb", serial="emulator-5580", grpc_discovery=root / "discovery.ini",
                                   proto_python=root, wav=[fixture, fixture], expected=["Milk", "Bread"], output=root)
            attempted = []

            def command(values, **kwargs):
                arguments = values[3:]
                if arguments == ["shell", "getprop", "ro.kernel.qemu"]:
                    return b"1"
                if arguments == ["emu", "avd", "name"]:
                    return b"QShopper_API_36"
                if arguments == ["shell", "settings", "get", "secure", "default_input_method"]:
                    return b"com.google.android.inputmethod.latin"
                if arguments == ["shell", "getprop", "sys.boot_completed"]:
                    return b"1"
                attempted.append(arguments)
                raise OSError("ADB disconnected")

            class BrokenAudio:
                def __init__(self, *args):
                    pass

                def require_host_microphone_disabled(self):
                    raise RuntimeError("preflight disconnected")

                def close(self):
                    raise RuntimeError("channel close failed")

            with patch.object(driver.argparse.ArgumentParser, "parse_args", return_value=args), \
                    patch.object(driver, "SyntheticAudio", BrokenAudio), \
                    patch.object(driver.subprocess, "check_output", side_effect=command):
                with self.assertRaises(RuntimeError):
                    driver.main()
            self.assertEqual(len(attempted), 3)
            report = json.loads((root / "cleanup.json").read_text())
            self.assertEqual([item["action"] for item in report["errors"]],
                             ["public-key/channel", "app", "app-data", "staging"])


if __name__ == "__main__":
    unittest.main()
