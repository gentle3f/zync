#!/usr/bin/env python3
"""Audit privacy manifests for Zync's privacy-sensitive iOS Flutter plugins."""

from __future__ import annotations

import argparse
import json
import plistlib
from pathlib import Path
from urllib.parse import unquote, urlparse

REQUIRED_MANIFEST_PACKAGES = {
    "flutter_secure_storage_darwin",
    "google_sign_in_ios",
    "mobile_scanner",
    "shared_preferences_foundation",
    "url_launcher_ios",
}


def _package_root(root_uri: str, package_config: Path) -> Path:
    parsed = urlparse(root_uri)
    if parsed.scheme == "file":
        path = Path(unquote(parsed.path))
        # Windows file URIs begin /C:/...
        if len(path.as_posix()) >= 3 and path.as_posix()[0] == "/" and path.as_posix()[2] == ":":
            path = Path(path.as_posix()[1:])
        return path
    if parsed.scheme:
        raise ValueError(f"unsupported package root URI: {root_uri}")
    return (package_config.parent / unquote(root_uri)).resolve()


def audit(package_config: Path) -> dict[str, Path]:
    if not package_config.is_file():
        raise ValueError(f"package_config.json missing: {package_config}")
    data = json.loads(package_config.read_text(encoding="utf-8"))
    packages = {
        item["name"]: _package_root(item["rootUri"], package_config)
        for item in data.get("packages", [])
        if isinstance(item, dict) and "name" in item and "rootUri" in item
    }

    missing_packages = sorted(REQUIRED_MANIFEST_PACKAGES - packages.keys())
    if missing_packages:
        raise ValueError(
            "required iOS plugin packages missing: " + ", ".join(missing_packages)
        )

    found: dict[str, Path] = {}
    for name in sorted(REQUIRED_MANIFEST_PACKAGES):
        root = packages[name]
        manifests = list(root.rglob("PrivacyInfo.xcprivacy"))
        if not manifests:
            raise ValueError(f"{name} no longer contains PrivacyInfo.xcprivacy")
        if len(manifests) != 1:
            raise ValueError(
                f"{name} contains unexpected privacy-manifest count: {len(manifests)}"
            )
        manifest = manifests[0]
        try:
            with manifest.open("rb") as handle:
                payload = plistlib.load(handle)
        except (plistlib.InvalidFileException, OSError) as error:
            raise ValueError(f"{name} has invalid privacy manifest: {error}") from error

        if payload.get("NSPrivacyTracking") is not False:
            raise ValueError(f"{name} privacy manifest unexpectedly enables tracking")
        if payload.get("NSPrivacyTrackingDomains") not in (None, []):
            raise ValueError(f"{name} privacy manifest unexpectedly declares tracking domains")
        found[name] = manifest

    shared = None
    with found["shared_preferences_foundation"].open("rb") as handle:
        shared = plistlib.load(handle)
    accessed = shared.get("NSPrivacyAccessedAPITypes")
    if not isinstance(accessed, list):
        raise ValueError("shared_preferences_foundation has no accessed-API declaration")

    user_defaults = [
        item
        for item in accessed
        if isinstance(item, dict)
        and item.get("NSPrivacyAccessedAPIType")
        == "NSPrivacyAccessedAPICategoryUserDefaults"
    ]
    if len(user_defaults) != 1:
        raise ValueError(
            "shared_preferences_foundation must declare UserDefaults exactly once"
        )
    reasons = user_defaults[0].get("NSPrivacyAccessedAPITypeReasons")
    if not isinstance(reasons, list) or not reasons:
        raise ValueError(
            "shared_preferences_foundation UserDefaults declaration has no reason"
        )

    return found


def self_test() -> None:
    # Exercise validation logic against a synthetic package config/tree.
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        entries = []
        for name in REQUIRED_MANIFEST_PACKAGES:
            package_root = root / name
            resources = package_root / "darwin/Resources"
            resources.mkdir(parents=True)
            payload = {
                "NSPrivacyTracking": False,
                "NSPrivacyTrackingDomains": [],
                "NSPrivacyCollectedDataTypes": [],
                "NSPrivacyAccessedAPITypes": [],
            }
            if name == "shared_preferences_foundation":
                payload["NSPrivacyAccessedAPITypes"] = [
                    {
                        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
                        "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
                    }
                ]
            with (resources / "PrivacyInfo.xcprivacy").open("wb") as handle:
                plistlib.dump(payload, handle)
            entries.append(
                {
                    "name": name,
                    "rootUri": package_root.as_uri(),
                    "packageUri": "lib/",
                }
            )
        config_dir = root / "app/.dart_tool"
        config_dir.mkdir(parents=True)
        config = config_dir / "package_config.json"
        config.write_text(
            json.dumps({"configVersion": 2, "packages": entries}),
            encoding="utf-8",
        )
        result = audit(config)
        assert set(result) == REQUIRED_MANIFEST_PACKAGES

    print("Zync iOS dependency privacy audit self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "package_config",
        nargs="?",
        default=".dart_tool/package_config.json",
    )
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    try:
        found = audit(Path(args.package_config))
    except (ValueError, json.JSONDecodeError) as error:
        parser.exit(1, f"iOS dependency privacy audit failed: {error}\n")

    for name, path in sorted(found.items()):
        print(f"{name}: {path}")
    print("Zync iOS dependency privacy audit passed")


if __name__ == "__main__":
    main()
