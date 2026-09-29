#!/usr/bin/env python3
"""Capture real simulator screens and render Solis's App Store artwork. No pip dependencies."""

import argparse
import datetime
import html
import json
from pathlib import Path
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "media/app-store/config.json"


def run(args, *, log=None, check=True, timeout=600):
    args = [str(arg) for arg in args]
    if log:
        with log.open("w") as output:
            result = subprocess.run(args, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
        if check and result.returncode:
            print("\n".join(log.read_text(errors="replace").splitlines()[-45:]), file=sys.stderr)
            raise RuntimeError(f"Command failed. Full log: {log}")
        return result
    result = subprocess.run(args, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=timeout)
    if check and result.returncode:
        raise RuntimeError(f"{' '.join(args)}\n{result.stderr.strip()}")
    return result


def validate_png(path, device, *, opaque=False):
    header = path.read_bytes()[:33]
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise RuntimeError(f"Not a PNG: {path}")
    width, height, depth, color_type = struct.unpack(">IIBB", header[16:26])
    if (width, height) != (device["width"], device["height"]):
        raise RuntimeError(f"Unexpected dimensions for {path}: {width} × {height}")
    if opaque and (depth != 8 or color_type != 2):
        raise RuntimeError(f"Expected opaque 8-bit RGB PNG: {path}")


def export_captures(result, raw, work, config, device):
    attachments = work / "attachments"
    run(["xcrun", "xcresulttool", "export", "attachments", "--path", result,
         "--output-path", attachments])
    manifest = json.loads((attachments / "manifest.json").read_text())
    raw.mkdir(parents=True, exist_ok=True)
    for screen in config["screens"]:
        prefix = "appstore-" + screen["id"]
        matches = [
            attachment for test in manifest for attachment in test["attachments"]
            if attachment["suggestedHumanReadableName"].startswith(prefix)
            and attachment["exportedFileName"].endswith(".png")
        ]
        if len(matches) != 1:
            raise RuntimeError(f"Expected exactly one {prefix}, found {len(matches)}. See {attachments}")
        target = raw / (screen["id"] + ".png")
        shutil.copy2(attachments / matches[0]["exportedFileName"], target)
        validate_png(target, device)


def capture(device, config, output, derived, work):
    name = f"Solis Screenshots {device['id']} {uuid.uuid4().hex[:6]}"
    device_id = run(["xcrun", "simctl", "create", name, device["deviceType"], config["runtime"]]).stdout.strip()
    print(f"Capturing {device['name']} on an isolated simulator…", flush=True)
    try:
        run(["env", f"IOS_LOOP_UDID={device_id}", "scripts/ios-loop-sim.sh", "--shutdown-older"])
        run(["xcrun", "simctl", "bootstatus", device_id, "-b"], log=work / "boot.log")
        # simctl's ISO parser requires fractional seconds.
        status_time = datetime.datetime(2026, 9, 17, 9, 41).astimezone().isoformat(timespec="milliseconds")
        run(["xcrun", "simctl", "status_bar", device_id, "override", "--time", status_time,
             "--dataNetwork", "wifi", "--wifiMode", "active", "--wifiBars", "3",
             "--cellularMode", "active", "--cellularBars", "4",
             "--batteryState", "discharging", "--batteryLevel", "100"])
        run(["xcrun", "simctl", "ui", device_id, "appearance", "light"])
        run(["xcrun", "simctl", "ui", device_id, "content_size", "medium"])
        result = work / "screenshots.xcresult"
        run(["xcodebuild", "test-without-building", "-quiet", "-project", "SunriseSunset.xcodeproj", "-scheme", "SolisScreenshots",
             "-destination", f"platform=iOS Simulator,id={device_id}",
             "-derivedDataPath", derived, "-resultBundlePath", result,
             "-only-testing:SunriseSunsetUITests/AppStoreScreenshotTests",
             "-parallel-testing-enabled", "NO", "-maximum-concurrent-test-simulator-destinations", "1",
             "-test-timeouts-enabled", "YES", "-default-test-execution-time-allowance", "120",
             "COMPILER_INDEX_STORE_ENABLE=NO"], log=work / "capture.log")
        export_captures(result, output / "raw" / config["locale"] / device["id"], work, config, device)
    finally:
        # Delete only the simulator created by this invocation, even when tests fail.
        run(["xcrun", "simctl", "shutdown", device_id], check=False)
        deleted = run(["xcrun", "simctl", "delete", device_id], check=False)
        if deleted.returncode:
            print(f"Could not delete screenshot simulator {device_id}: {deleted.stderr}", file=sys.stderr)


def gallery(config, output):
    sections = []
    for device in config["devices"]:
        folder = output / "upload" / config["locale"] / device["id"]
        if not all((folder / (s["id"] + ".png")).exists() for s in config["screens"]):
            continue
        figures = []
        for screen in config["screens"]:
            path = (folder / (screen["id"] + ".png")).relative_to(output)
            title = html.escape(screen["headline"].replace("\n", " "))
            figures.append(f'<a href="{path}"><img src="{path}" alt="{title}"><span>{title}</span></a>')
        sections.append(f'<section><h2>{html.escape(device["name"])} <small>{device["width"]} × {device["height"]}</small></h2><div>{"".join(figures)}</div></section>')
    page = """<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Solis · App Store screenshots</title><style>
body{margin:0;padding:40px;background:#f5f4f6;color:#242127;font:16px -apple-system,BlinkMacSystemFont,sans-serif}
main{max-width:1500px;margin:auto}h1{font-size:32px;letter-spacing:-1px}p,small{color:#69636e}h2{margin:40px 0 18px;font-size:21px}
small{font-size:14px;font-weight:400;margin-left:12px}section div{display:grid;grid-template-columns:repeat(4,1fr);gap:20px}
a{color:inherit;text-decoration:none}img{width:100%;display:block;border-radius:12px;box-shadow:0 4px 18px #19102014}span{display:block;margin-top:12px;font-size:13px}
@media(max-width:800px){body{padding:20px}section div{grid-template-columns:repeat(2,1fr)}}
</style><main><h1>Solis App Store screenshots</h1><p>Click an image to open the full-resolution PNG. Upload the PNG files in each device folder.</p><p><a href="solis-app-store-screenshots.zip" download>Download all upload-ready screenshots</a></p>"""
    (output / "index.html").write_text(page + "".join(sections) + "</main></html>")


def package(config, output):
    with zipfile.ZipFile(output / "solis-app-store-screenshots.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for device in config["devices"]:
            folder = output / "upload" / config["locale"] / device["id"]
            paths = [folder / (screen["id"] + ".png") for screen in config["screens"]]
            if all(path.exists() for path in paths):
                for path in paths:
                    validate_png(path, device, opaque=True)
                    archive.write(path, path.relative_to(output / "upload"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", action="append", help="Device ID from config.json; repeat to select several")
    parser.add_argument("--render-only", action="store_true", help="Re-render existing raw captures without running simulators")
    parser.add_argument("--skip-build", action="store_true", help="Reuse a previously built screenshot test bundle")
    parser.add_argument("--output", type=Path, default=ROOT / "media/app-store",
                        help="Directory for raw captures, artwork, previews, and ZIP")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/app-store",
                        help="Directory for build caches, logs, and test results")
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text())
    if config["locale"] != "en-CA":
        raise RuntimeError("The current screenshot fixture and UI tests support en-CA. Localize the tests before changing locale.")
    devices = [d for d in config["devices"] if not args.device or d["id"] in args.device]
    unknown = set(args.device or []) - {d["id"] for d in devices}
    if unknown:
        raise RuntimeError(f"Unknown device IDs: {', '.join(sorted(unknown))}")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    build = args.build_dir.resolve()
    build.mkdir(parents=True, exist_ok=True)
    derived = build / "DerivedData"
    work = Path(tempfile.mkdtemp(prefix="run-", dir=build))
    # Match the configuration used for this run even if the source is later edited.
    shutil.copy2(CONFIG, work / "config.json")
    if not args.render_only:
        runtimes = json.loads(run(["xcrun", "simctl", "list", "runtimes", "-j"]).stdout)["runtimes"]
        if not any(r["identifier"] == config["runtime"] and r["isAvailable"] for r in runtimes):
            raise RuntimeError(f"Install {config['runtime']} in Xcode Settings > Components, or update {CONFIG}")
        if not args.skip_build:
            print("Building screenshot tests…", flush=True)
            run(["xcodebuild", "build-for-testing", "-quiet", "-project", "SunriseSunset.xcodeproj", "-scheme", "SolisScreenshots",
                 "-destination", "generic/platform=iOS Simulator", "-derivedDataPath", derived,
                 "COMPILER_INDEX_STORE_ENABLE=NO"], log=work / "build.log")
    renderer = work / "render"
    print("Compiling artwork renderer…", flush=True)
    run(["xcrun", "swiftc", "-module-cache-path", build / "SwiftModuleCache",
         ROOT / "scripts/render-app-store.swift", "-o", renderer], log=work / "renderer.log")
    for device in devices:
        device_work = work / device["id"]
        device_work.mkdir()
        if not args.render_only:
            capture(device, config, output, derived, device_work)
        raw = output / "raw" / config["locale"] / device["id"]
        destination = output / "upload" / config["locale"] / device["id"]
        staged = device_work / "rendered"
        run([renderer, work / "config.json", raw, staged, device["id"]], log=device_work / "render.log")
        for screen in config["screens"]:
            validate_png(staged / (screen["id"] + ".png"), device, opaque=True)
        shutil.copytree(staged, destination, dirs_exist_ok=True)
        shutil.copy2(device_work / (device["id"] + "-contact-sheet.png"), destination.parent)
        print(f"Ready: {destination}", flush=True)
    metadata = {
        "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "revision": run(["git", "rev-parse", "HEAD"]).stdout.strip(),
        "workingTreeStatus": run(["git", "status", "--porcelain"]).stdout,
        "xcode": run(["xcodebuild", "-version"]).stdout.strip(),
        "runtime": config["runtime"], "devices": [d["id"] for d in devices],
        "renderOnly": args.render_only,
    }
    (work / "manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
    gallery(config, output)
    package(config, output)
    print(f"Review: {output / 'index.html'}\nRun details: {work}", flush=True)


def interrupted(signum, frame):
    raise KeyboardInterrupt


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupted)
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError, KeyboardInterrupt) as error:
        print(f"Screenshot generation stopped: {error}", file=sys.stderr)
        sys.exit(1)
