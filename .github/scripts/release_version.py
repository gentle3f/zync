#!/usr/bin/env python3
"""Validate Zync Android release version inputs.

Production release runs must choose a version explicitly. The repository's
pubspec version is a development baseline only; signed-release workflow inputs
override it with Flutter --build-name/--build-number.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import tempfile
from pathlib import Path

_VERSION_NAME_RE = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
MAX_ANDROID_VERSION_CODE = 2_100_000_000


def validate_version_name(value: str) -> str:
    clean = value.strip()
    if not _VERSION_NAME_RE.fullmatch(clean):
        raise ValueError(
            "version name must be an explicit numeric major.minor.patch "
            "(for example 1.0.1)"
        )
    return clean


def validate_version_code(value: str | int) -> int:
    raw = str(value).strip()
    if not raw.isdigit():
        raise ValueError("version code must be a positive integer")
    code = int(raw)
    if code < 1 or code > MAX_ANDROID_VERSION_CODE:
        raise ValueError(
            f"version code must be between 1 and {MAX_ANDROID_VERSION_CODE}"
        )
    return code


def verify_ios_info_plist(
    path: Path,
    *,
    expected_bundle_id: str,
    expected_version_name: str,
    expected_build_number: str | int,
) -> None:
    if not path.is_file():
        raise ValueError(f"iOS Info.plist missing: {path}")
    try:
        with path.open("rb") as handle:
            info = plistlib.load(handle)
    except (plistlib.InvalidFileException, OSError) as error:
        raise ValueError(f"invalid iOS Info.plist: {error}") from error

    version_name = validate_version_name(expected_version_name)
    build_number = validate_version_code(expected_build_number)

    if info.get("CFBundleIdentifier") != expected_bundle_id:
        raise ValueError(
            f"iOS bundle ID mismatch: {info.get('CFBundleIdentifier')} != {expected_bundle_id}"
        )
    if str(info.get("CFBundleShortVersionString", "")) != version_name:
        raise ValueError(
            "iOS versionName mismatch: "
            f"{info.get('CFBundleShortVersionString')} != {version_name}"
        )
    if str(info.get("CFBundleVersion", "")) != str(build_number):
        raise ValueError(
            f"iOS build number mismatch: {info.get('CFBundleVersion')} != {build_number}"
        )


def verify_android_output_metadata(
    path: Path,
    *,
    expected_package: str,
    expected_version_name: str,
    expected_version_code: str | int,
) -> None:
    if not path.is_file():
        raise ValueError(f"Android output metadata missing: {path}")
    try:
        payload = json.loads(path.read_text(encoding="utf-8-sig"))
    except (json.JSONDecodeError, UnicodeDecodeError) as error:
        raise ValueError(f"invalid Android output metadata: {error}") from error

    if payload.get("applicationId") != expected_package:
        raise ValueError(
            f"Android package mismatch: {payload.get('applicationId')} != {expected_package}"
        )

    version_name = validate_version_name(expected_version_name)
    version_code = validate_version_code(expected_version_code)
    elements = payload.get("elements")
    if not isinstance(elements, list) or len(elements) != 1:
        raise ValueError("Android output metadata must contain exactly one release element")

    element = elements[0]
    if element.get("versionName") != version_name:
        raise ValueError(
            f"Android versionName mismatch: {element.get('versionName')} != {version_name}"
        )
    if element.get("versionCode") != version_code:
        raise ValueError(
            f"Android versionCode mismatch: {element.get('versionCode')} != {version_code}"
        )


def self_test() -> None:
    for good in ("1.0.0", "1.0.1", "2.10.35", "10.0.0"):
        assert validate_version_name(good) == good

    for bad in ("", "1", "1.0", "01.0.0", "1.0.0-beta", "v1.0.0", "1.0.0+7"):
        try:
            validate_version_name(bad)
        except ValueError:
            pass
        else:
            raise AssertionError(f"invalid version name accepted: {bad!r}")

    for good in ("1", 7, "2100000000"):
        assert validate_version_code(good) == int(good)

    for bad in ("", "0", "-1", "1.5", "2100000001", "abc"):
        try:
            validate_version_code(bad)
        except ValueError:
            pass
        else:
            raise AssertionError(f"invalid version code accepted: {bad!r}")

    with tempfile.TemporaryDirectory() as tmp:
        metadata = Path(tmp) / "output-metadata.json"
        metadata.write_text(
            json.dumps(
                {
                    "applicationId": "com.gmail.gentle3f.myproject",
                    "elements": [
                        {
                            "versionCode": 7,
                            "versionName": "1.0.1",
                            "outputFile": "AndroidManifest.xml",
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        verify_android_output_metadata(
            metadata,
            expected_package="com.gmail.gentle3f.myproject",
            expected_version_name="1.0.1",
            expected_version_code=7,
        )

        ios_info = Path(tmp) / "Info.plist"
        with ios_info.open("wb") as handle:
            plistlib.dump(
                {
                    "CFBundleIdentifier": "com.gmail.gentle3f.myproject",
                    "CFBundleShortVersionString": "1.0.1",
                    "CFBundleVersion": "7",
                },
                handle,
            )
        verify_ios_info_plist(
            ios_info,
            expected_bundle_id="com.gmail.gentle3f.myproject",
            expected_version_name="1.0.1",
            expected_build_number=7,
        )

        try:
            verify_android_output_metadata(
                metadata,
                expected_package="com.gmail.gentle3f.myproject",
                expected_version_name="1.0.1",
                expected_version_code=8,
            )
        except ValueError as error:
            assert "versionCode mismatch" in str(error)
        else:
            raise AssertionError("Android output metadata version mismatch was not rejected")

    print("Zync release-version validator self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--version-name")
    parser.add_argument("--version-code")
    parser.add_argument("--android-metadata")
    parser.add_argument("--expected-package")
    parser.add_argument("--ios-info-plist")
    parser.add_argument("--expected-bundle-id")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    if args.version_name is None or args.version_code is None:
        parser.error("--version-name and --version-code are required")

    try:
        name = validate_version_name(args.version_name)
        code = validate_version_code(args.version_code)
        if args.android_metadata:
            if not args.expected_package:
                parser.error("--expected-package is required with --android-metadata")
            verify_android_output_metadata(
                Path(args.android_metadata),
                expected_package=args.expected_package,
                expected_version_name=name,
                expected_version_code=code,
            )
        if args.ios_info_plist:
            if not args.expected_bundle_id:
                parser.error("--expected-bundle-id is required with --ios-info-plist")
            verify_ios_info_plist(
                Path(args.ios_info_plist),
                expected_bundle_id=args.expected_bundle_id,
                expected_version_name=name,
                expected_build_number=code,
            )
    except ValueError as error:
        parser.exit(1, f"Release version validation failed: {error}\n")

    print(f"Release version validated: {name}+{code}")


if __name__ == "__main__":
    main()