#!/usr/bin/env python3
"""Apply and validate Zync's app-level iOS privacy manifest.

The repository keeps no long-lived ios/ tree, so the generated Runner target
must receive PrivacyInfo.xcprivacy deterministically every time a wrapper is
created.

This manifest describes Zync app-level collection only. Third-party SDKs remain
responsible for their own privacy manifests / required-reason API declarations.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import re
import tempfile
from pathlib import Path

MANIFEST_NAME = "PrivacyInfo.xcprivacy"
BUILD_ID = hashlib.sha1(b"Zync PrivacyInfo.xcprivacy PBXBuildFile").hexdigest()[:24].upper()
FILE_ID = hashlib.sha1(b"Zync PrivacyInfo.xcprivacy PBXFileReference").hexdigest()[:24].upper()

SPEC_PATH = Path(__file__).resolve().parents[1] / "app_store_privacy_details.json"


def load_privacy_spec(path: Path = SPEC_PATH) -> dict[str, object]:
    if not path.is_file():
        raise ValueError(f"App Store privacy source file missing: {path}")
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as error:
        raise ValueError(f"invalid App Store privacy source: {error}") from error

    if payload.get("schemaVersion") != 1:
        raise ValueError("unsupported App Store privacy schemaVersion")
    if payload.get("tracking") is not False:
        raise ValueError("Zync production privacy spec must keep tracking=false")
    if payload.get("trackingDomains") != []:
        raise ValueError("trackingDomains must stay empty while tracking=false")
    if payload.get("appRequiredReasonApis") != []:
        raise ValueError(
            "appRequiredReasonApis must stay empty unless Zync app code directly uses "
            "a required-reason API"
        )

    collected = payload.get("collectedData")
    if not isinstance(collected, list) or not collected:
        raise ValueError("privacy spec collectedData must be a non-empty list")

    allowed_types = {
        "NSPrivacyCollectedDataTypeEmailAddress",
        "NSPrivacyCollectedDataTypeProductInteraction",
        "NSPrivacyCollectedDataTypeUserID",
    }
    seen: set[str] = set()
    for item in collected:
        if not isinstance(item, dict):
            raise ValueError("privacy spec collectedData entries must be objects")
        data_type = item.get("appleType")
        if data_type not in allowed_types:
            raise ValueError(f"unexpected Zync collected data type: {data_type!r}")
        if data_type in seen:
            raise ValueError(f"duplicate Zync collected data type: {data_type}")
        seen.add(data_type)
        if item.get("linkedToUser") is not True:
            raise ValueError(f"{data_type} must remain linkedToUser=true")
        if item.get("tracking") is not False:
            raise ValueError(f"{data_type} must remain tracking=false")
        if item.get("purposes") != [
            "NSPrivacyCollectedDataTypePurposeAppFunctionality"
        ]:
            raise ValueError(f"{data_type} purpose must stay AppFunctionality")

    if seen != allowed_types:
        raise ValueError(
            "privacy spec must declare exactly EmailAddress, ProductInteraction, "
            "and UserID"
        )

    production_analytics = payload.get("productionAnalytics")
    if not isinstance(production_analytics, dict) or production_analytics.get(
        "enabled"
    ) is not False:
        raise ValueError("productionAnalytics.enabled must remain false")

    return payload


def manifest_payload() -> dict[str, object]:
    spec = load_privacy_spec()
    collected = spec["collectedData"]
    assert isinstance(collected, list)
    return {
        "NSPrivacyTracking": spec["tracking"],
        "NSPrivacyTrackingDomains": spec["trackingDomains"],
        "NSPrivacyCollectedDataTypes": [
            {
                "NSPrivacyCollectedDataType": item["appleType"],
                "NSPrivacyCollectedDataTypeLinked": item["linkedToUser"],
                "NSPrivacyCollectedDataTypeTracking": item["tracking"],
                "NSPrivacyCollectedDataTypePurposes": item["purposes"],
            }
            for item in collected
            if isinstance(item, dict)
        ],
        # Zync's Dart app code does not directly call required-reason APIs.
        # Plugins must declare their own native required-reason usage.
        "NSPrivacyAccessedAPITypes": spec["appRequiredReasonApis"],
    }


def write_manifest(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        plistlib.dump(manifest_payload(), handle, sort_keys=False)


def validate_manifest(path: Path) -> None:
    if not path.is_file():
        raise ValueError(f"privacy manifest missing: {path}")
    try:
        with path.open("rb") as handle:
            payload = plistlib.load(handle)
    except (plistlib.InvalidFileException, OSError) as error:
        raise ValueError(f"invalid privacy manifest: {error}") from error

    if payload != manifest_payload():
        raise ValueError("privacy manifest does not match Zync's locked app-level declaration")


def _insert_before(text: str, anchor: str, line: str) -> str:
    if line in text:
        return text
    if anchor not in text:
        raise ValueError(f"Xcode project anchor missing: {anchor}")
    return text.replace(anchor, line + "\n" + anchor, 1)


def patch_project(text: str) -> str:
    build_line = (
        f"\t\t{BUILD_ID} /* {MANIFEST_NAME} in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {FILE_ID} /* {MANIFEST_NAME} */; }};"
    )
    file_line = (
        f"\t\t{FILE_ID} /* {MANIFEST_NAME} */ = "
        "{isa = PBXFileReference; lastKnownFileType = text.plist.xml; "
        f"path = {MANIFEST_NAME}; sourceTree = \"<group>\"; }};"
    )

    if BUILD_ID in text and build_line not in text:
        raise ValueError("privacy PBXBuildFile ID collides with existing Xcode project content")
    if FILE_ID in text and file_line not in text:
        raise ValueError("privacy PBXFileReference ID collides with existing Xcode project content")

    text = _insert_before(text, "/* End PBXBuildFile section */", build_line)
    text = _insert_before(text, "/* End PBXFileReference section */", file_line)

    runner_marker = "/* Runner */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = ("
    runner_pos = text.find(runner_marker)
    if runner_pos < 0:
        raise ValueError("Runner PBXGroup not found")
    runner_end = text.find("\n\t\t\t);", runner_pos)
    if runner_end < 0:
        raise ValueError("Runner PBXGroup children terminator not found")
    runner_block = text[runner_pos:runner_end]
    child_line = f"\n\t\t\t\t{FILE_ID} /* {MANIFEST_NAME} */,"
    if child_line.strip() not in runner_block:
        insert_at = text.find(
            "\n\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,",
            runner_pos,
            runner_end,
        )
        if insert_at < 0:
            insert_at = runner_end
        text = text[:insert_at] + child_line + text[insert_at:]

    # Find Runner's resources phase by its canonical resource contents instead of
    # relying on the numeric phase ID.
    resources_pattern = re.compile(
        r"(isa = PBXResourcesBuildPhase;\n"
        r"\s*buildActionMask = 2147483647;\n"
        r"\s*files = \(\n)"
        r"(?P<files>.*?Main\.storyboard in Resources.*?\n)"
        r"(\s*\);)",
        re.DOTALL,
    )
    match = resources_pattern.search(text)
    if not match:
        raise ValueError("Runner PBXResourcesBuildPhase not found")
    resource_line = f"\t\t\t\t{BUILD_ID} /* {MANIFEST_NAME} in Resources */,\n"
    if resource_line not in match.group(0):
        insertion = match.start("files")
        text = text[:insertion] + resource_line + text[insertion:]

    return text


def configure(root: Path) -> None:
    project_path = root / "ios/Runner.xcodeproj/project.pbxproj"
    manifest_path = root / f"ios/Runner/{MANIFEST_NAME}"
    if not project_path.is_file():
        raise ValueError(f"generated iOS project missing: {project_path}")

    write_manifest(manifest_path)
    original = project_path.read_text(encoding="utf-8")
    patched = patch_project(original)
    project_path.write_text(patched, encoding="utf-8")


def check(root: Path) -> None:
    project_path = root / "ios/Runner.xcodeproj/project.pbxproj"
    manifest_path = root / f"ios/Runner/{MANIFEST_NAME}"
    validate_manifest(manifest_path)
    if not project_path.is_file():
        raise ValueError("generated iOS Xcode project missing")

    text = project_path.read_text(encoding="utf-8")
    expected = {
        f"{BUILD_ID} /* {MANIFEST_NAME} in Resources */": 2,
        f"{FILE_ID} /* {MANIFEST_NAME} */": 3,
    }
    # PBXBuildFile appears once in declaration + once in Resources phase.
    # PBXFileReference appears in the PBXBuildFile fileRef, once in its own
    # declaration, and once in the Runner group.
    for marker, count in expected.items():
        actual = text.count(marker)
        if actual != count:
            raise ValueError(
                f"privacy manifest Xcode reference count mismatch for {marker}: "
                f"{actual} != {count}"
            )


def self_test() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        project = root / "ios/Runner.xcodeproj/project.pbxproj"
        project.parent.mkdir(parents=True)
        project.write_text(
            """/* Begin PBXBuildFile section */
		AAAAAAAAAAAAAAAAAAAAAAAA /* Main.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = BBBBBBBBBBBBBBBBBBBBBBBB /* Main.storyboard */; };
/* End PBXBuildFile section */
/* Begin PBXFileReference section */
		CCCCCCCCCCCCCCCCCCCCCCCC /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
/* End PBXFileReference section */
		DDDDDDDDDDDDDDDDDDDDDDDD /* Runner */ = {
			isa = PBXGroup;
			children = (
				97C147021CF9000F007C117D /* Info.plist */,
			);
			path = Runner;
			sourceTree = "<group>";
		};
		EEEEEEEEEEEEEEEEEEEEEEEE /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AAAAAAAAAAAAAAAAAAAAAAAA /* Main.storyboard in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
""",
            encoding="utf-8",
        )
        configure(root)
        check(root)
        before = project.read_text(encoding="utf-8")
        configure(root)
        assert project.read_text(encoding="utf-8") == before
        payload = manifest_payload()
        assert payload["NSPrivacyTracking"] is False
        assert {
            item["NSPrivacyCollectedDataType"]
            for item in payload["NSPrivacyCollectedDataTypes"]
        } == {
            "NSPrivacyCollectedDataTypeEmailAddress",
            "NSPrivacyCollectedDataTypeProductInteraction",
            "NSPrivacyCollectedDataTypeUserID",
        }

    print("Zync iOS privacy-manifest helper self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build_app")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--check-manifest")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    try:
        if args.check_manifest:
            validate_manifest(Path(args.check_manifest))
            print("Zync iOS privacy manifest file check passed")
        elif args.check:
            check(Path(args.root))
            print("Zync iOS privacy manifest integration check passed")
        else:
            configure(Path(args.root))
            print("Applied Zync iOS privacy manifest")
    except ValueError as error:
        parser.exit(1, f"iOS privacy-manifest configuration failed: {error}\n")


if __name__ == "__main__":
    main()