#!/usr/bin/env python3
"""Capture REAL in-app App Store screenshots for ChineseChess via the simulator
and DEBUG CC_CAPTURE/CC_SKIP_ONBOARDING launch args (home|board|opening|select|
midgame). Two locales now that real in-app zh-Hant localization exists (2026-08-24
compliance-gate fix) — app_language is set via `defaults write` since
LocalizationManager reads a persisted UserDefaults key, not an env var. The "home"
shot now shows the real trial/free-tier state (the 2026-08-24 double-gating fix),
not a fake fully-unlocked view. Output: screenshots/final/{en,zh-Hant}/*.png
"""
import os
import re
import subprocess
import time
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent
PROJECT = APP_DIR / "ChineseChess.xcodeproj"
SCHEME = "ChineseChess"
BUNDLE = "com.quyenngo.chinesechess"

SHOTS = [
    ("01-home",    {"CC_SKIP_ONBOARDING": "1", "CC_CAPTURE": "home"}),
    ("02-board",   {"CC_SKIP_ONBOARDING": "1", "CC_CAPTURE": "board"}),
    ("03-opening", {"CC_SKIP_ONBOARDING": "1", "CC_CAPTURE": "opening"}),
    ("04-select",  {"CC_SKIP_ONBOARDING": "1", "CC_CAPTURE": "select"}),
    ("05-midgame", {"CC_SKIP_ONBOARDING": "1", "CC_CAPTURE": "midgame"}),
]

LANGUAGES = {"en": "en", "zh-Hant": "zh-Hant"}


def sh(*a, **k):
    return subprocess.run(a, check=True, capture_output=True, text=True, **k)


def find_device():
    out = subprocess.run(["xcrun", "simctl", "list", "devices", "available"],
                          capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = re.search(r"^\s*(iPhone .*Pro Max)\s+\(([0-9A-F\-]{36})\)", line)
        if m:
            return m.group(2), m.group(1)
    raise SystemExit("No available 'iPhone ... Pro Max' simulator found")


def build_app():
    sh("xcodebuild", "-project", str(PROJECT), "-scheme", SCHEME, "-configuration", "Debug",
       "-sdk", "iphonesimulator", "-derivedDataPath", str(APP_DIR / "build/sim"), "build",
       cwd=str(APP_DIR))
    app = APP_DIR / "build/sim/Build/Products/Debug-iphonesimulator/ChineseChess.app"
    if not app.exists():
        raise SystemExit(f"built app not found at {app}")
    return app


def main():
    device, name = find_device()
    print(f"==> device {name}")
    app = build_app()
    subprocess.run(["xcrun", "simctl", "shutdown", device], capture_output=True)
    subprocess.run(["xcrun", "simctl", "erase", device], capture_output=True)
    subprocess.run(["xcrun", "simctl", "boot", device], capture_output=True)
    sh("xcrun", "simctl", "bootstatus", device, "-b")
    subprocess.run(["xcrun", "simctl", "status_bar", device, "override", "--time", "9:41",
                     "--batteryLevel", "100", "--batteryState", "charged",
                     "--cellularBars", "4", "--wifiBars", "3"], capture_output=True)
    sh("xcrun", "simctl", "install", device, str(app))
    time.sleep(8)  # let a first-boot "Ready for Apple Intelligence" banner auto-dismiss (2026-08-24)

    for lang_dir, app_lang in LANGUAGES.items():
        out = APP_DIR / "screenshots" / "final" / lang_dir
        out.mkdir(parents=True, exist_ok=True)
        # `defaults delete` does NOT reliably clear this app's UserDefaults on this
        # simulator/Xcode version (found 2026-08-24 — a stale firstLaunchDate from
        # real 2026-08-09 testing survived it, making a "fresh install" screenshot
        # show an already-expired trial). Uninstall+reinstall for a genuinely clean
        # container instead.
        subprocess.run(["xcrun", "simctl", "uninstall", device, BUNDLE], capture_output=True)
        sh("xcrun", "simctl", "install", device, str(app))
        time.sleep(8)  # let a first-boot "Ready for Apple Intelligence" banner auto-dismiss (2026-08-24)
        sh("xcrun", "simctl", "launch", device, BUNDLE,
           env=dict(os.environ, SIMCTL_CHILD_CC_SKIP_ONBOARDING="1"))
        time.sleep(2)
        subprocess.run(["xcrun", "simctl", "terminate", device, BUNDLE], capture_output=True)
        sh("xcrun", "simctl", "spawn", device, "defaults", "write", BUNDLE,
           "app_language", "-string", app_lang)

        print(f"  -- {lang_dir} --")
        for shotname, envvars in SHOTS:
            subprocess.run(["xcrun", "simctl", "terminate", device, BUNDLE], capture_output=True)
            subprocess.run(
                ["xcrun", "simctl", "launch", device, BUNDLE],
                env=dict(os.environ, **{f"SIMCTL_CHILD_{k}": v for k, v in envvars.items()}),
                capture_output=True,
            )
            time.sleep(4)
            out_path = out / f"{shotname}.png"
            sh("xcrun", "simctl", "io", device, "screenshot", str(out_path))
            print(f"    wrote {out_path.name}")

    subprocess.run(["xcrun", "simctl", "terminate", device, BUNDLE], capture_output=True)
    print("==> done.")


if __name__ == "__main__":
    main()
