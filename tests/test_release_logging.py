"""Exercise real application startup/logging with disposable storage.

Requires a Release desktop app; --debug-app also checks Debug defaults.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, required=True)
    parser.add_argument("--debug-app", type=Path)
    parser.add_argument("--qt-bin", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("out/release-logging"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    results = []

    def run(name, rules="", broken=False, debug=False):
        with tempfile.TemporaryDirectory(prefix="qshopper-logging-") as temporary:
            data = Path(temporary) / "data"
            if broken:
                data.write_text("A file cannot be the storage directory.")
            env = os.environ.copy()
            env.update(QSHOPPER_DATA_DIR=str(data), QT_QUICK_BACKEND="software",
                       QT_FORCE_STDERR_LOGGING="1", QT_MESSAGE_PATTERN="%{type}|%{category}|%{message}",
                       QT_LOGGING_RULES=rules)
            env["PATH"] = str(args.qt_bin) + os.pathsep + env.get("PATH", "")
            executable = args.debug_app if debug else args.app
            with subprocess.Popen([str(executable.resolve()), "-platform", "offscreen"], env=env,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
                try:
                    deadline = time.monotonic() + 15
                    if broken:
                        process.wait(timeout=15)
                    else:
                        while time.monotonic() < deadline:
                            assert process.poll() is None, "Application exited before storage was ready"
                            database = data / "shop_list.sqlite"
                            if database.exists() and database.stat().st_size > 0:
                                break
                            time.sleep(.1)
                        else:
                            raise AssertionError("Application storage did not initialize")
                        time.sleep(1.2)
                        assert process.poll() is None, "Application failed during QML startup"
                finally:
                    if process.poll() is None:
                        process.terminate()
                    stdout, stderr = process.communicate(timeout=10)
            text = (stdout + stderr).decode(errors="replace")
            (args.output / f"{name}.txt").write_text(text, encoding="utf-8")
            if not broken:
                assert not re.search(r"Type .* unavailable|is not a type|ReferenceError:|TypeError:", text), \
                    "Application QML did not load successfully; see the captured log"
            return text, process.returncode

    def check(name, passed):
        results.append(dict(case=name, passed=bool(passed)))
        (args.output / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if passed else "FAIL ") + name, flush=True)
        assert passed, name

    normal, _ = run("release-default")
    verbose = r"Database location:|Load from | id:|Drop table "
    check("release_normal_startup_is_quiet", not re.search(verbose, normal)
          and "debug|qshopper." not in normal and "info|qshopper." not in normal)
    enabled, _ = run("release-opt-in", "qshopper.*.debug=true")
    check("release_debug_can_be_enabled", "debug|qshopper.app|Database location:" in enabled
          and "debug|qshopper.model|Load from " in enabled)
    cmake = (Path(__file__).resolve().parents[1] / "CMakeLists.txt").read_text()
    version = re.search(r"project\(QShopper VERSION ([0-9.]+)", cmake).group(1)
    check("runtime_version_matches_cmake", f'Starting QShopper "{version}"' in enabled)
    model_only, _ = run("model-only", "qshopper.app.debug=false;qshopper.model.debug=true")
    check("categories_can_be_selected_independently", "Database location:" not in model_only
          and "debug|qshopper.model|Load from " in model_only)
    warning, exit_code = run("release-warning", broken=True)
    check("release_storage_failure_remains_actionable", exit_code != 0
          and "warning|qshopper.app|Failed to create directory" in warning)
    if args.debug_app:
        development, _ = run("debug-default", debug=True)
        check("debug_default_retains_diagnostics", "debug|qshopper.app|Database location:" in development
              and "debug|qshopper.model|Load from " in development)
        disabled, _ = run("debug-disabled", "qshopper.*.debug=false", debug=True)
        check("debug_categories_can_be_silenced", not re.search(verbose, disabled))


if __name__ == "__main__":
    main()
