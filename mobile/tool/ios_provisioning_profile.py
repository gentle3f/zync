#!/usr/bin/env python3
"""Validate an App Store Connect provisioning-profile plist for Zync iOS.

The CMS envelope must be decoded before calling this helper (on macOS:
`security cms -D -i profile.mobileprovision > profile.plist`). This helper
never needs the private distribution certificate or its password.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import plistlib
import re
import tempfile
from pathlib import Path

_TEAM_RE = re.compile(r"^[A-Z0-9]{10}$")
_UUID_RE = re.compile(
    r"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
)
_BUNDLE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]+$")


def _utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def validate_profile(
    path: Path,
    *,
    expected_bundle_id: str,
    now: datetime | None = None,
) -> dict[str, str]:
    if not _BUNDLE_RE.fullmatch(expected_bundle_id):
        raise ValueError("invalid expected iOS bundle identifier")
    if not path.is_file():
        raise ValueError(f"provisioning-profile plist missing: {path}")

    try:
        with path.open("rb") as handle:
            profile = plistlib.load(handle)
    except (plistlib.InvalidFileException, OSError) as error:
        raise ValueError(f"invalid provisioning-profile plist: {error}") from error

    teams = profile.get("TeamIdentifier")
    if not isinstance(teams, list) or len(teams) != 1:
        raise ValueError("profile must contain exactly one TeamIdentifier")
    team_id = str(teams[0]).strip()
    if not _TEAM_RE.fullmatch(team_id):
        raise ValueError("profile TeamIdentifier is invalid")

    uuid = str(profile.get("UUID", "")).strip()
    if not _UUID_RE.fullmatch(uuid):
        raise ValueError("profile UUID is invalid")

    name = str(profile.get("Name", "")).strip()
    if not name or "\n" in name or "\r" in name:
        raise ValueError("profile Name is missing/unsafe")

    platform = profile.get("Platform")
    if not isinstance(platform, list) or "iOS" not in platform:
        raise ValueError("profile is not an iOS provisioning profile")

    expiration = profile.get("ExpirationDate")
    if not isinstance(expiration, datetime):
        raise ValueError("profile ExpirationDate is missing")
    expiration_utc = _utc(expiration)
    now_utc = _utc(now or datetime.now(timezone.utc))
    if expiration_utc <= now_utc:
        raise ValueError("provisioning profile is expired")

    # App Store distribution profiles must not be device-bound or enterprise.
    provisioned_devices = profile.get("ProvisionedDevices")
    if provisioned_devices:
        raise ValueError(
            "provisioning profile contains ProvisionedDevices; "
            "use an App Store Connect distribution profile"
        )
    if profile.get("ProvisionsAllDevices") is True:
        raise ValueError(
            "enterprise provisioning profile is not allowed for App Store archive"
        )

    entitlements = profile.get("Entitlements")
    if not isinstance(entitlements, dict):
        raise ValueError("profile Entitlements are missing")

    expected_app_id = f"{team_id}.{expected_bundle_id}"
    if entitlements.get("application-identifier") != expected_app_id:
        raise ValueError(
            "profile application-identifier does not match TeamIdentifier + bundle ID"
        )
    if entitlements.get("com.apple.developer.team-identifier") != team_id:
        raise ValueError("profile team entitlement does not match TeamIdentifier")
    if entitlements.get("get-task-allow") is not False:
        raise ValueError(
            "profile get-task-allow must be false for distribution/App Store use"
        )

    apple_sign_in = entitlements.get("com.apple.developer.applesignin")
    if not isinstance(apple_sign_in, list) or "Default" not in apple_sign_in:
        raise ValueError(
            "profile is missing the Sign in with Apple Default entitlement"
        )

    return {
        "team_id": team_id,
        "profile_uuid": uuid.upper(),
        "profile_name": name,
        "expiration": expiration_utc.isoformat().replace("+00:00", "Z"),
    }


def self_test() -> None:
    fixed_now = datetime(2026, 9, 28, tzinfo=timezone.utc)
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "profile.plist"
        payload = {
            "Name": "Zync App Store",
            "UUID": "12345678-1234-4ABC-9DEF-1234567890AB",
            "TeamIdentifier": ["A1B2C3D4E5"],
            "Platform": ["iOS"],
            "ExpirationDate": datetime(2027, 9, 28),
            "Entitlements": {
                "application-identifier": "A1B2C3D4E5.com.gmail.gentle3f.myproject",
                "com.apple.developer.team-identifier": "A1B2C3D4E5",
                "get-task-allow": False,
                "com.apple.developer.applesignin": ["Default"],
            },
        }
        with path.open("wb") as handle:
            plistlib.dump(payload, handle)

        result = validate_profile(
            path,
            expected_bundle_id="com.gmail.gentle3f.myproject",
            now=fixed_now,
        )
        assert result["team_id"] == "A1B2C3D4E5"
        assert result["profile_name"] == "Zync App Store"

        payload["ProvisionedDevices"] = ["0000000000000000000000000000000000000000"]
        with path.open("wb") as handle:
            plistlib.dump(payload, handle)
        try:
            validate_profile(
                path,
                expected_bundle_id="com.gmail.gentle3f.myproject",
                now=fixed_now,
            )
        except ValueError as error:
            assert "ProvisionedDevices" in str(error)
        else:
            raise AssertionError("device-bound profile was not rejected")

    print("Zync iOS provisioning-profile validator self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--plist")
    parser.add_argument("--expected-bundle-id")
    parser.add_argument("--github-output")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    if not args.plist or not args.expected_bundle_id:
        parser.error("--plist and --expected-bundle-id are required")

    try:
        result = validate_profile(
            Path(args.plist),
            expected_bundle_id=args.expected_bundle_id,
        )
    except ValueError as error:
        parser.exit(1, f"iOS provisioning-profile validation failed: {error}\n")

    if args.github_output:
        with Path(args.github_output).open("a", encoding="utf-8") as handle:
            for key in ("team_id", "profile_uuid", "profile_name", "expiration"):
                handle.write(f"{key}={result[key]}\n")

    print(
        "iOS provisioning profile validated: "
        f"team_id={result['team_id']} "
        f"uuid={result['profile_uuid']} "
        f"expires={result['expiration']}"
    )


if __name__ == "__main__":
    main()
