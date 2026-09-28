#!/usr/bin/env python3
"""Apply deterministic manual App Store signing to a generated Zync iOS wrapper."""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import tempfile
from pathlib import Path

DEFAULT_BUNDLE_ID = "com.gmail.gentle3f.myproject"

_TEAM_RE = re.compile(r"^[A-Z0-9]{10}$")
_UUID_RE = re.compile(
    r"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
)
_BUNDLE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]+$")


def _pbx_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def validate_inputs(
    *,
    bundle_id: str,
    team_id: str,
    profile_uuid: str,
    profile_name: str,
) -> None:
    if not _BUNDLE_RE.fullmatch(bundle_id):
        raise ValueError("invalid iOS bundle identifier")
    if not _TEAM_RE.fullmatch(team_id):
        raise ValueError("Apple team ID must be exactly 10 uppercase alphanumeric characters")
    if not _UUID_RE.fullmatch(profile_uuid):
        raise ValueError("provisioning profile UUID is invalid")
    if not profile_name.strip() or "\n" in profile_name or "\r" in profile_name:
        raise ValueError("provisioning profile name is missing/unsafe")


def signing_lines(
    *,
    indent: str,
    team_id: str,
    profile_uuid: str,
    profile_name: str,
) -> list[str]:
    return [
        f"{indent}CODE_SIGN_STYLE = Manual;",
        f"{indent}DEVELOPMENT_TEAM = {team_id};",
        f'{indent}"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";',
        f"{indent}PROVISIONING_PROFILE = {_pbx_quote(profile_uuid.upper())};",
        f"{indent}PROVISIONING_PROFILE_SPECIFIER = {_pbx_quote(profile_name)};",
    ]


def patch_project(
    text: str,
    *,
    bundle_id: str,
    team_id: str,
    profile_uuid: str,
    profile_name: str,
) -> str:
    validate_inputs(
        bundle_id=bundle_id,
        team_id=team_id,
        profile_uuid=profile_uuid,
        profile_name=profile_name,
    )

    target_line = f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};"
    lines = text.splitlines()
    indices = [i for i, line in enumerate(lines) if line.strip() == target_line]
    if len(indices) != 3:
        raise ValueError(
            f"expected 3 Runner bundle-id build settings, found {len(indices)}"
        )

    # Patch bottom-up so indices remain stable.
    for index in reversed(indices):
        indent = lines[index][: len(lines[index]) - len(lines[index].lstrip())]
        expected = signing_lines(
            indent=indent,
            team_id=team_id,
            profile_uuid=profile_uuid,
            profile_name=profile_name,
        )
        lookback = lines[max(0, index - 8) : index]
        if all(item in lookback for item in expected):
            continue

        # A generated wrapper should not already carry conflicting target-level
        # manual signing. Fail rather than silently layering two identities.
        for raw in lookback:
            stripped = raw.strip()
            if (
                stripped.startswith("PROVISIONING_PROFILE =")
                or stripped.startswith("PROVISIONING_PROFILE_SPECIFIER =")
                or stripped.startswith("DEVELOPMENT_TEAM =")
            ):
                raise ValueError(
                    "Runner configuration already contains conflicting manual signing"
                )

        lines[index:index] = expected

    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


def export_options(
    *,
    bundle_id: str,
    team_id: str,
    profile_name: str,
) -> dict[str, object]:
    return {
        "method": "app-store-connect",
        "destination": "export",
        "signingStyle": "manual",
        "teamID": team_id,
        "signingCertificate": "Apple Distribution",
        "provisioningProfiles": {
            bundle_id: profile_name,
        },
        "manageAppVersionAndBuildNumber": False,
        "stripSwiftSymbols": True,
    }


def configure(
    root: Path,
    *,
    bundle_id: str,
    team_id: str,
    profile_uuid: str,
    profile_name: str,
    export_options_path: Path,
) -> None:
    project_path = root / "ios/Runner.xcodeproj/project.pbxproj"
    if not project_path.is_file():
        raise ValueError(f"generated iOS project missing: {project_path}")

    original = project_path.read_text(encoding="utf-8")
    patched = patch_project(
        original,
        bundle_id=bundle_id,
        team_id=team_id,
        profile_uuid=profile_uuid,
        profile_name=profile_name,
    )
    project_path.write_text(patched, encoding="utf-8")

    export_options_path.parent.mkdir(parents=True, exist_ok=True)
    with export_options_path.open("wb") as handle:
        plistlib.dump(
            export_options(
                bundle_id=bundle_id,
                team_id=team_id,
                profile_name=profile_name,
            ),
            handle,
            sort_keys=False,
        )


def check(
    root: Path,
    *,
    bundle_id: str,
    team_id: str,
    profile_uuid: str,
    profile_name: str,
    export_options_path: Path,
) -> None:
    project_path = root / "ios/Runner.xcodeproj/project.pbxproj"
    if not project_path.is_file() or not export_options_path.is_file():
        raise ValueError("iOS signing project/export options are incomplete")

    text = project_path.read_text(encoding="utf-8")
    settings = signing_lines(
        indent="",
        team_id=team_id,
        profile_uuid=profile_uuid,
        profile_name=profile_name,
    )
    # Strip indentation because real pbxproj indentation varies by config.
    stripped_lines = [line.strip() for line in text.splitlines()]
    for setting in settings:
        count = stripped_lines.count(setting.strip())
        if count != 3:
            raise ValueError(
                f"expected signing setting exactly 3 times: {setting.strip()} (found {count})"
            )

    if stripped_lines.count(f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};") != 3:
        raise ValueError("Runner bundle identifier is not applied to all 3 configs")

    with export_options_path.open("rb") as handle:
        options = plistlib.load(handle)
    expected = export_options(
        bundle_id=bundle_id,
        team_id=team_id,
        profile_name=profile_name,
    )
    if options != expected:
        raise ValueError("ExportOptions.plist does not match expected App Store signing")


def self_test() -> None:
    sample = "".join(
        [
            "\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n"
            "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gmail.gentle3f.myproject;\n"
            for _ in range(3)
        ]
    )
    patched = patch_project(
        sample,
        bundle_id=DEFAULT_BUNDLE_ID,
        team_id="A1B2C3D4E5",
        profile_uuid="12345678-1234-4ABC-9DEF-1234567890AB",
        profile_name="Zync App Store",
    )
    assert patched.count("CODE_SIGN_STYLE = Manual;") == 3
    assert patched.count("DEVELOPMENT_TEAM = A1B2C3D4E5;") == 3
    assert patched.count("Apple Distribution") == 3
    assert patched.count("Zync App Store") == 3

    # Must be idempotent.
    assert (
        patch_project(
            patched,
            bundle_id=DEFAULT_BUNDLE_ID,
            team_id="A1B2C3D4E5",
            profile_uuid="12345678-1234-4ABC-9DEF-1234567890AB",
            profile_name="Zync App Store",
        )
        == patched
    )

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "ExportOptions.plist"
        with path.open("wb") as handle:
            plistlib.dump(
                export_options(
                    bundle_id=DEFAULT_BUNDLE_ID,
                    team_id="A1B2C3D4E5",
                    profile_name="Zync App Store",
                ),
                handle,
                sort_keys=False,
            )
        with path.open("rb") as handle:
            payload = plistlib.load(handle)
        assert payload["method"] == "app-store-connect"
        assert payload["manageAppVersionAndBuildNumber"] is False

    print("Zync iOS manual-signing helper self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build_app")
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument("--team-id")
    parser.add_argument("--profile-uuid")
    parser.add_argument("--profile-name")
    parser.add_argument("--export-options", default="build_app/ios/ExportOptions.plist")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    required = {
        "--team-id": args.team_id,
        "--profile-uuid": args.profile_uuid,
        "--profile-name": args.profile_name,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        parser.error("missing required arguments: " + ", ".join(missing))

    kwargs = dict(
        bundle_id=args.bundle_id,
        team_id=args.team_id,
        profile_uuid=args.profile_uuid,
        profile_name=args.profile_name,
        export_options_path=Path(args.export_options),
    )
    try:
        if args.check:
            check(Path(args.root), **kwargs)
            print("Zync iOS manual-signing check passed")
        else:
            configure(Path(args.root), **kwargs)
            print("Applied Zync iOS manual App Store signing")
    except ValueError as error:
        parser.exit(1, f"iOS signing configuration failed: {error}\n")


if __name__ == "__main__":
    main()
