"""Opt-in English Gboard dictation using synthetic WAVs, never the host microphone.

Requires grpcio, cryptography and generated emulator_controller Python
bindings. See tests/README.md for the authenticated emulator and fixture setup.
Only QShopper_API_36 on emulator-5580 and its configured Gboard layout are supported.
"""

import argparse
import base64
from contextlib import closing
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import subprocess
import sys
import tempfile
import time
import uuid
import wave
import xml.etree.ElementTree as ET

PACKAGE = "shopper.nevala.com"
TABLE = "11111111-1111-1111-1111-111111111111"
GBOARD = "com.google.android.inputmethod.latin"


class SyntheticAudio:
    """Ephemeral public JWK; the private key/token are never written or printed."""

    def __init__(self, discovery, proto_python):
        import grpc
        from cryptography.hazmat.primitives.asymmetric import ec

        config = dict(line.split("=", 1) for line in discovery.read_text().splitlines() if "=" in line)
        assert config["avd.id"] == "QShopper_API_36" and config["port.serial"] == "5580"
        assert "-grpc-use-jwt" in config["cmdline"], "JWT authentication is required"
        sys.path.insert(0, str(proto_python.resolve()))
        import emulator_controller_pb2 as messages
        import emulator_controller_pb2_grpc as service

        self.messages = messages
        self.key = ec.generate_private_key(ec.SECP256R1())
        self.kid = "qshopper-" + uuid.uuid4().hex
        public = self.key.public_key().public_numbers()
        jwk = dict(kty="EC", crv="P-256", alg="ES256", kid=self.kid,
                   x=self.encode(public.x.to_bytes(32, "big")), y=self.encode(public.y.to_bytes(32, "big")))
        self.path = Path(config["grpc.jwks"]) / (self.kid + ".jwk")
        self.channel = None
        try:
            self.path.write_text(json.dumps({"keys": [jwk]}), encoding="utf-8")
            self.channel = grpc.insecure_channel("127.0.0.1:" + config["grpc.port"])
            self.stub = service.EmulatorControllerStub(self.channel)
            time.sleep(1)  # Let the emulator's JWK watcher read this public key.
        except Exception:
            self.close()
            raise

    @staticmethod
    def encode(value):
        return base64.urlsafe_b64encode(value).rstrip(b"=").decode()

    def metadata(self):
        from cryptography.hazmat.primitives import hashes
        from cryptography.hazmat.primitives.asymmetric import ec, utils

        prefix = "/android.emulation.control.EmulatorController/"
        header = self.encode(json.dumps(dict(alg="ES256", kid=self.kid)).encode())
        claims = self.encode(json.dumps(dict(iss="qshopper-local-test", iat=int(time.time()) - 5,
                            exp=int(time.time()) + 60,
                            aud=[prefix + name for name in ("getMicrophoneState", "injectAudio")])).encode())
        message = (header + "." + claims).encode()
        r, s = utils.decode_dss_signature(self.key.sign(message, ec.ECDSA(hashes.SHA256())))
        token = header + "." + claims + "." + self.encode(r.to_bytes(32, "big") + s.to_bytes(32, "big"))
        return [("authorization", "Bearer " + token)]

    def require_host_microphone_disabled(self):
        from google.protobuf.empty_pb2 import Empty

        state = self.stub.getMicrophoneState(Empty(), metadata=self.metadata(), timeout=5)
        assert not state.realAudioEnabled, "Stop: host microphone access must remain disabled"

    def inject(self, path):
        self.require_host_microphone_disabled()
        with wave.open(str(path), "rb") as source:
            assert source.getnchannels() == 1 and source.getsampwidth() == 2
            assert 8000 <= source.getframerate() <= 48000
            assert 0 < source.getnframes() / source.getframerate() <= 15
            rate = source.getframerate()
            fmt = self.messages.AudioFormat(samplingRate=rate, channels=self.messages.AudioFormat.Mono,
                        format=self.messages.AudioFormat.AUD_FMT_S16, mode=self.messages.AudioFormat.MODE_REAL_TIME)

            def packets():
                while data := source.readframes(rate // 10):
                    yield self.messages.AudioPacket(format=fmt, audio=data)
                    time.sleep(len(data) / (rate * 2))

            # Do not nest another RPC inside the stream iterator. Blocking audio
            # delivery can stall when Gboard is not recording; pace real-time PCM.
            self.stub.injectAudio(packets(), metadata=self.metadata(), timeout=25)
        self.require_host_microphone_disabled()

    def close(self):
        try:
            if self.channel is not None:
                self.channel.close()
        finally:
            self.path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default="emulator-5580", choices=("emulator-5580",))
    parser.add_argument("--grpc-discovery", type=Path, required=True)
    parser.add_argument("--proto-python", type=Path, required=True)
    parser.add_argument("--wav", type=Path, action="append", required=True)
    parser.add_argument("--expected", action="append", required=True,
                        help="Exact English recognition transcript for each WAV, in the same order")
    parser.add_argument("--output", type=Path, default=Path("out/android-dictation"))
    args = parser.parse_args()
    if (len(args.wav) != 2 or any(not path.is_file() for path in args.wav) or len(args.expected) != 2
            or any(not transcript.strip() for transcript in args.expected)):
        parser.error("Provide two synthetic English WAVs and two exact expected transcripts")
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *map(str, command)], timeout=45)

    def shell(*command):
        return adb("shell", *command).decode().replace("\r", "").strip()

    def tree(tag):
        path = "/data/local/tmp/qshopper-voice-" + uuid.uuid4().hex + ".xml"
        try:
            assert "dumped to" in shell("uiautomator", "dump", path)
            raw = adb("exec-out", "cat", path)
            (args.output / (tag + ".xml")).write_bytes(raw)
            (args.output / (tag + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
            return ET.fromstring(raw)
        finally:
            shell("rm", "-f", path)

    def field(ui):
        return ui.find(f'.//node[@class="android.widget.EditText"][@package="{PACKAGE}"]')

    def keyboard():
        return "mInputShown=true" in shell("dumpsys", "input_method")

    def key(x, y):
        display = shell("dumpsys", "window", "displays")
        ime = re.search(r"type=ime frame=\[0,(\d+)\]\[(\d+),\d+\][^\n]*visible=true", display)
        nav = re.search(r"type=navigationBars frame=\[0,(\d+)\]\[\d+,\d+\][^\n]*visible=true", display)
        assert ime and nav, "Visible Gboard insets were not found"
        return round(int(ime[2]) * x), round(int(ime[1]) + (int(nav[1]) - int(ime[1])) * y)

    def saved():
        snapshot = args.output / "saved.sqlite"
        snapshot.write_bytes(adb("exec-out", "run-as", PACKAGE, "cat", data + "/shop_list.sqlite"))
        with closing(sqlite3.connect(snapshot)) as db:
            return db.execute(f'SELECT name,checked,id FROM "{TABLE}" ORDER BY rowid').fetchall()

    results = []

    def check(name, passed, **details):
        results.append(dict(case=name, passed=bool(passed), **details))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        assert passed, name

    assert shell("getprop", "ro.kernel.qemu") == "1"
    assert "QShopper_API_36" in adb("emu", "avd", "name").decode()
    assert GBOARD in shell("settings", "get", "secure", "default_input_method")
    assert shell("getprop", "sys.boot_completed") == "1"
    audio = None
    data = f"/data/user/0/{PACKAGE}/files/agent-testing/dictation-{uuid.uuid4().hex}"
    staging = "/data/local/tmp/qshopper-voice-" + uuid.uuid4().hex + ".sqlite"
    try:
        audio = SyntheticAudio(args.grpc_discovery, args.proto_python)
        (args.output / "data-path.txt").write_text(data, encoding="utf-8")
        audio.require_host_microphone_disabled()
        with tempfile.TemporaryDirectory(prefix="qshopper-voice-") as temporary:
            fixture = Path(temporary) / "fixture.sqlite"
            with closing(sqlite3.connect(fixture)) as db:
                schema = "(id TEXT PRIMARY KEY NOT NULL,name TEXT NOT NULL,checked INTEGER NOT NULL DEFAULT 0)"
                db.execute("CREATE TABLE lists " + schema)
                db.execute("INSERT INTO lists VALUES (?, 'default', 0)", (TABLE,))
                db.execute(f'CREATE TABLE "{TABLE}" ' + schema)
                db.commit()
            adb("push", fixture, staging)
        shell("am", "force-stop", PACKAGE)
        shell("run-as", PACKAGE, "mkdir", "-p", data)
        shell("run-as", PACKAGE, "cp", staging, data + "/shop_list.sqlite")

        def launch():
            shell("am", "start", "-n", PACKAGE + "/org.qtproject.qt.android.bindings.QtActivity",
                  "--es", "extraenvvars_QSHOPPER_DATA_DIR", data)
            for attempt in range(6):
                ui = tree("launch-" + str(attempt))
                if field(ui) is not None or any("TextDelegate_" in n.get("resource-id", "") for n in ui.iter("node")):
                    return ui
                time.sleep(.3)
            raise AssertionError("Disposable app fixture did not load")

        ui = launch()
        rect = list(map(int, re.findall(r"\d+", field(ui).get("bounds"))))
        shell("input", "tap", (rect[0] + rect[2]) // 2, (rect[1] + rect[3]) // 2)
        ui = tree("keyboard")
        check("native_gboard_open", keyboard())
        expected = []
        for index, source in enumerate(args.wav):
            audio.require_host_microphone_disabled()
            mic = key(.945, .065)
            # Like test_entry.py, this driver targets the configured English
            # Gboard layout. Complete its first-use prompts before this test.
            shell("input", "tap", *mic)
            tree(f"entry-{index}-voice-open")
            audio.inject(source)
            time.sleep(2)
            ui = tree(f"entry-{index}-recognized")
            recognized = field(ui).get("text")
            check(f"entry-{index}-speech-recognized", recognized == args.expected[index],
                  recognized=recognized, expected=args.expected[index],
                  wav_sha256=hashlib.sha256(source.read_bytes()).hexdigest())
            submitted = recognized
            if index == 1:
                shell("input", "tap", *key(.5, .82))  # Actual Gboard Space commits its composition.
                ui = tree("space-committed")
                submitted = field(ui).get("text")
                check("space_commit_preserves_recognized_text", submitted in (recognized, recognized + " "),
                      recognized=recognized, committed=submitted)
            shell("input", "tap", *key(.925, .82))
            ui = tree(f"entry-{index}-return")
            records = saved()
            actual = records[-1][0] if records else None
            accepted = actual == submitted or index == 0 and actual == submitted + " "
            check(f"entry-{index}-return-saves-one-item", len(records) == index + 1
                  and records[:-1] == expected and records[-1][1] == 0 and accepted,
                  recognized=recognized, before_return=submitted, saved=actual,
                  comparison="exact" if index else "exact or one terminal ASCII space at IME commit")
            expected = records
            check(f"entry-{index}-return-clears-draft-keeps-keyboard", field(ui).get("text") == "" and keyboard())
        shell("am", "force-stop", PACKAGE)
        launch()
        check("cold_restart_preserves_exact_dictated_records", saved() == expected)
        audio.require_host_microphone_disabled()
        check("host_microphone_remains_disabled", True)
    finally:
        errors = []
        actions = [("public-key/channel", lambda: audio.close() if audio is not None else None),
                   ("app", lambda: shell("am", "force-stop", PACKAGE)),
                   ("app-data", lambda: shell("run-as", PACKAGE, "rm", "-rf", data)),
                   ("staging", lambda: shell("rm", "-f", staging))]
        for name, action in actions:
            try:
                action()
            except Exception as error:
                errors.append(dict(action=name, error=str(error)))
        (args.output / "cleanup.json").write_text(json.dumps(dict(errors=errors), indent=2), encoding="utf-8")
        if errors:
            raise RuntimeError("Dictation cleanup incomplete; see cleanup.json")


if __name__ == "__main__":
    main()
