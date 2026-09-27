#!/usr/bin/env python3
"""Configure Google identity metadata in a generated Flutter iOS wrapper.

Authentication itself is performed through the official google_sign_in_ios
Flutter plugin from Dart, including the server challenge nonce. The native
wrapper only needs the dedicated iOS OAuth client ID and reversed URL scheme.
"""

from __future__ import annotations

import argparse
import os
import plistlib
import re
from pathlib import Path


CLIENT_SUFFIX = ".apps.googleusercontent.com"


def reversed_client_id(client_id: str) -> str:
    clean = client_id.strip()
    if not clean.endswith(CLIENT_SUFFIX):
        raise SystemExit("iOS Google client ID must end with .apps.googleusercontent.com")
    prefix = clean[: -len(CLIENT_SUFFIX)]
    if not prefix or not re.fullmatch(r"[A-Za-z0-9._-]+", prefix):
        raise SystemExit("iOS Google client ID has an invalid prefix")
    return f"com.googleusercontent.apps.{prefix}"


def patch_info_plist(path: Path, ios_client_id: str) -> None:
    with path.open("rb") as handle:
        info = plistlib.load(handle)

    scheme = reversed_client_id(ios_client_id)
    info["GIDClientID"] = ios_client_id

    url_types = info.get("CFBundleURLTypes")
    if not isinstance(url_types, list):
        url_types = []

    filtered = []
    for entry in url_types:
        if not isinstance(entry, dict):
            continue
        schemes = entry.get("CFBundleURLSchemes")
        if isinstance(schemes, list) and any(
            isinstance(value, str) and value.startswith("com.googleusercontent.apps.")
            for value in schemes
        ):
            continue
        filtered.append(entry)

    filtered.append(
        {
            "CFBundleTypeRole": "Editor",
            "CFBundleURLSchemes": [scheme],
        }
    )
    info["CFBundleURLTypes"] = filtered

    with path.open("wb") as handle:
        plistlib.dump(info, handle, sort_keys=False)


def configure(root: Path, ios_client_id: str) -> None:
    info = root / "ios/Runner/Info.plist"
    app_delegate = root / "ios/Runner/AppDelegate.swift"
    if not info.exists() or not app_delegate.exists():
        raise SystemExit(f"Generated iOS wrapper not found under {root}")

    patch_info_plist(info, ios_client_id)

    # The generated Flutter AppDelegate must remain the default plugin
    # registration surface. google_sign_in_ios owns native lifecycle handling.
    source = app_delegate.read_text(encoding="utf-8")
    if "GeneratedPluginRegistrant.register" not in source:
        raise SystemExit("Generated iOS AppDelegate is missing plugin registration")

    print("Configured Zync iOS Google identity metadata")
    print(f"client_id={ios_client_id}")
    print(f"url_scheme={reversed_client_id(ios_client_id)}")
    print("provider=google_sign_in_ios")


def check_template(root: Path) -> None:
    app_delegate = root / "ios/Runner/AppDelegate.swift"
    info = root / "ios/Runner/Info.plist"
    pubspec = root / "pubspec.yaml"
    if not app_delegate.exists() or not info.exists() or not pubspec.exists():
        raise SystemExit("Generated iOS wrapper is incomplete")

    source = app_delegate.read_text(encoding="utf-8")
    if "GeneratedPluginRegistrant.register" not in source:
        raise SystemExit("Generated iOS AppDelegate is missing plugin registration")
    if "import GoogleSignIn" in source or "zync/google_identity" in source:
        raise SystemExit("iOS wrapper should use the Flutter Google plugin, not a custom native bridge")

    with info.open("rb") as handle:
        plist = plistlib.load(handle)
    client_id = str(plist.get("GIDClientID", "")).strip()
    if not client_id.endswith(CLIENT_SUFFIX):
        raise SystemExit("Generated iOS wrapper is missing GIDClientID")
    expected_scheme = reversed_client_id(client_id)
    schemes = [
        scheme
        for entry in plist.get("CFBundleURLTypes", [])
        if isinstance(entry, dict)
        for scheme in entry.get("CFBundleURLSchemes", [])
        if isinstance(scheme, str)
    ]
    if expected_scheme not in schemes:
        raise SystemExit("Generated iOS wrapper is missing reversed Google URL scheme")

    pubspec_text = pubspec.read_text(encoding="utf-8")
    if "google_sign_in_ios:" not in pubspec_text:
        raise SystemExit("Generated iOS wrapper is missing google_sign_in_ios dependency")

    print("Zync iOS Google identity metadata check passed")


def self_test() -> None:
    sample = "1234567890-zyncios.apps.googleusercontent.com"
    assert reversed_client_id(sample) == "com.googleusercontent.apps.1234567890-zyncios"
    print("Zync iOS Google identity metadata self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build_app")
    parser.add_argument(
        "--ios-client-id",
        default=os.environ.get("ZYNC_GOOGLE_IOS_CLIENT_ID", ""),
    )
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--check-template", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    root = Path(args.root)
    if args.check_template:
        check_template(root)
        return

    client_id = args.ios_client_id.strip()
    if not client_id:
        raise SystemExit(
            "Provide --ios-client-id or set ZYNC_GOOGLE_IOS_CLIENT_ID; "
            "do not reuse the Web client ID."
        )
    configure(root, client_id)


if __name__ == "__main__":
    main()
