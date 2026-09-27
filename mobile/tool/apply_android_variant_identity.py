#!/usr/bin/env python3
"""Apply an Android package/label variant to a generated Zync wrapper.

Used for QA/diagnostic builds so package identity changes are reproducible and
not duplicated as inline workflow Python.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def patch_manifest(path: Path, label: str) -> None:
    text = path.read_text(encoding="utf-8")
    text, count = re.subn(
        r'android:label="[^"]*"',
        f'android:label="{label}"',
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("Could not patch Android app label")
    path.write_text(text, encoding="utf-8")


def patch_application_id(android_dir: Path, application_id: str) -> Path:
    candidates = [
        android_dir / "app/build.gradle.kts",
        android_dir / "app/build.gradle",
    ]
    for path in candidates:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        text = re.sub(
            r'applicationId\s*=\s*"[^"]+"',
            f'applicationId = "{application_id}"',
            text,
            count=1,
        )
        text = re.sub(
            r'applicationId\s+"[^"]+"',
            f'applicationId "{application_id}"',
            text,
            count=1,
        )
        if text == original:
            raise SystemExit(f"Could not patch applicationId in {path}")
        path.write_text(text, encoding="utf-8")
        return path
    raise SystemExit("Android app Gradle file not found")


def configure(root: Path, application_id: str, label: str) -> None:
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+", application_id):
        raise SystemExit("Invalid Android application ID")
    if not label.strip():
        raise SystemExit("Android label must not be empty")

    manifest = root / "android/app/src/main/AndroidManifest.xml"
    android_dir = root / "android"
    if not manifest.exists():
        raise SystemExit(f"Generated Android wrapper not found under {root}")

    patch_manifest(manifest, label.strip())
    gradle = patch_application_id(android_dir, application_id)

    print("Applied Zync Android variant identity")
    print(f"application_id={application_id}")
    print(f"label={label.strip()}")
    print(f"gradle={gradle}")


def self_test() -> None:
    assert re.fullmatch(
        r"[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+",
        "com.gmail.gentle3f.myproject.qa",
    )
    assert not re.fullmatch(
        r"[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+",
        "not a package",
    )
    print("Zync Android variant identity self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build_app")
    parser.add_argument("--application-id", required=False)
    parser.add_argument("--label", required=False)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    if not args.application_id or not args.label:
        raise SystemExit("--application-id and --label are required")
    configure(Path(args.root), args.application_id, args.label)


if __name__ == "__main__":
    main()
