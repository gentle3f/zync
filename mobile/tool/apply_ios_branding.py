#!/usr/bin/env python3
"""Apply Zync branding and baseline iOS permissions to a generated wrapper.

The iOS wrapper is disposable, so every native brand artifact must be
reproducible from source control. This script generates the same cream +
orange/plum linked-ring mark used by the Android wrapper for every AppIcon and
LaunchImage slot without third-party image tooling.
"""

from __future__ import annotations

import argparse
import json
import math
import plistlib
import re
import struct
import zlib
from pathlib import Path


CREAM = (255, 250, 246)
ORANGE = (255, 106, 33)
PLUM = (110, 90, 230)


def png_bytes(width: int, height: int, pixels: bytes, *, alpha: bool) -> bytes:
    channels = 4 if alpha else 3
    if len(pixels) != width * height * channels:
        raise ValueError("PNG pixel buffer has the wrong size")

    signature = b"\x89PNG\r\n\x1a\n"

    def chunk(kind: bytes, data: bytes) -> bytes:
        body = kind + data
        return (
            struct.pack(">I", len(data))
            + body
            + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)
        )

    color_type = 6 if alpha else 2
    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    stride = width * channels
    raw = b"".join(
        b"\x00" + pixels[row * stride : (row + 1) * stride]
        for row in range(height)
    )
    return signature + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def _stroke_coverage(x: float, y: float, cx: float, cy: float, radius: float, stroke: float, aa: float) -> float:
    distance = abs(math.hypot(x - cx, y - cy) - radius)
    inner = stroke / 2 - aa
    outer = stroke / 2 + aa
    if distance <= inner:
        return 1.0
    if distance >= outer:
        return 0.0
    return (outer - distance) / max(outer - inner, 1e-9)


def _blend(base: tuple[int, int, int, int], ink: tuple[int, int, int], coverage: float) -> tuple[int, int, int, int]:
    if coverage <= 0:
        return base
    coverage = max(0.0, min(1.0, coverage))
    br, bg, bb, ba = base
    # Coverage is source alpha; preserve a transparent launch-image background.
    source_alpha = coverage
    base_alpha = ba / 255
    out_alpha = source_alpha + base_alpha * (1 - source_alpha)
    if out_alpha <= 0:
        return (0, 0, 0, 0)
    return (
        round((ink[0] * source_alpha + br * base_alpha * (1 - source_alpha)) / out_alpha),
        round((ink[1] * source_alpha + bg * base_alpha * (1 - source_alpha)) / out_alpha),
        round((ink[2] * source_alpha + bb * base_alpha * (1 - source_alpha)) / out_alpha),
        round(out_alpha * 255),
    )


def render_mark(width: int, height: int, *, opaque_background: bool, mark_fraction: float) -> bytes:
    mark_px = min(width, height) * mark_fraction
    left = (width - mark_px) / 2
    top = (height - mark_px) / 2
    scale = mark_px / 108.0
    aa = 0.75 / max(scale, 1e-9)

    output = bytearray()
    for py in range(height):
        for px in range(width):
            if opaque_background:
                color = (*CREAM, 255)
            else:
                color = (0, 0, 0, 0)

            nx = (px + 0.5 - left) / scale
            ny = (py + 0.5 - top) / scale
            if -6 <= nx <= 114 and -6 <= ny <= 114:
                first = _stroke_coverage(nx, ny, 43.7, 54.0, 22.0, 8.2, aa)
                second = _stroke_coverage(nx, ny, 64.3, 54.0, 22.0, 8.2, aa)
                color = _blend(color, ORANGE, first)
                color = _blend(color, PLUM, second)

            if opaque_background:
                output.extend(color[:3])
            else:
                output.extend(color)

    return png_bytes(width, height, bytes(output), alpha=not opaque_background)


def write_icon_set(root: Path) -> None:
    icon_dir = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((icon_dir / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents.get("images", []):
        filename = entry.get("filename")
        size_text = entry.get("size")
        scale_text = entry.get("scale")
        if not filename or not size_text or not scale_text:
            continue
        points = float(str(size_text).split("x", 1)[0])
        multiplier = float(str(scale_text).rstrip("x"))
        pixels = int(round(points * multiplier))
        (icon_dir / filename).write_bytes(
            render_mark(pixels, pixels, opaque_background=True, mark_fraction=1.0)
        )


def write_launch_images(root: Path) -> None:
    launch_dir = root / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    logical_size = (168, 185)
    for multiplier, filename in (
        (1, "LaunchImage.png"),
        (2, "LaunchImage@2x.png"),
        (3, "LaunchImage@3x.png"),
    ):
        width = logical_size[0] * multiplier
        height = logical_size[1] * multiplier
        (launch_dir / filename).write_bytes(
            render_mark(
                width,
                height,
                opaque_background=False,
                mark_fraction=(108 / 185),
            )
        )


def patch_launch_storyboard(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    # Warm cream background: #FFFAF6.
    replacement = (
        '<color key="backgroundColor" red="1" green="0.9803921569" '
        'blue="0.9647058824" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>'
    )
    text, count = re.subn(
        r'<color key="backgroundColor"[^>]*/>',
        replacement,
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("Could not patch iOS LaunchScreen background")
    path.write_text(text, encoding="utf-8")


def patch_info_plist(path: Path) -> None:
    with path.open("rb") as handle:
        info = plistlib.load(handle)

    info["CFBundleDisplayName"] = "Zync"
    info["CFBundleName"] = "Zync"
    info["NSCameraUsageDescription"] = (
        "Zync uses the camera only when you choose to scan a Zync QR code."
    )

    with path.open("wb") as handle:
        plistlib.dump(info, handle, sort_keys=False)


def patch_project(path: Path, bundle_id: str) -> None:
    text = path.read_text(encoding="utf-8")
    text = re.sub(
        r"PRODUCT_BUNDLE_IDENTIFIER = [^;]+;",
        lambda match: (
            match.group(0)
            if ".RunnerTests" in match.group(0)
            else f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};"
        ),
        text,
    )
    text = re.sub(
        r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;",
        "IPHONEOS_DEPLOYMENT_TARGET = 15.0;",
        text,
    )
    path.write_text(text, encoding="utf-8")


def configure(root: Path, bundle_id: str) -> None:
    info = root / "ios/Runner/Info.plist"
    project = root / "ios/Runner.xcodeproj/project.pbxproj"
    launch = root / "ios/Runner/Base.lproj/LaunchScreen.storyboard"
    if not info.exists() or not project.exists() or not launch.exists():
        raise SystemExit(f"Generated iOS wrapper not found under {root}")

    patch_info_plist(info)
    patch_project(project, bundle_id)
    write_icon_set(root)
    write_launch_images(root)
    patch_launch_storyboard(launch)

    print("Applied Zync iOS branding")
    print(f"bundle_id={bundle_id}")
    print(f"info_plist={info}")
    print("app_icons=Zync linked-ring mark")
    print("launch_screen=Zync cream + linked-ring mark")


def self_test() -> None:
    assert re.fullmatch(r"[A-Za-z0-9.-]+", "com.gmail.gentle3f.myproject")
    sample = render_mark(40, 40, opaque_background=True, mark_fraction=1.0)
    assert sample.startswith(b"\x89PNG\r\n\x1a\n")
    transparent = render_mark(40, 44, opaque_background=False, mark_fraction=0.6)
    assert transparent.startswith(b"\x89PNG\r\n\x1a\n")
    print("Zync iOS branding self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build_app")
    parser.add_argument(
        "--bundle-id",
        default="com.gmail.gentle3f.myproject",
    )
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    if not re.fullmatch(r"[A-Za-z0-9.-]+", args.bundle_id):
        raise SystemExit("Invalid iOS bundle identifier")
    configure(Path(args.root), args.bundle_id)


if __name__ == "__main__":
    main()
