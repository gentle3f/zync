#!/usr/bin/env python3
"""Verify Zync signed-IPA provenance after macOS code-signature verification.

This helper verifies artifact/hash/version/profile/run provenance. It does not
replace Apple's `codesign --verify`; the archive workflow must perform that
cryptographic check first.
"""

from __future__ import annotations

import argparse
import hashlib
import plistlib
import re
import tempfile
import zipfile
from pathlib import Path

from release_version import validate_version_code, validate_version_name

_SHA256_RE = re.compile(r"^[0-9A-F]{64}$")
_SOURCE_SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")
_TEAM_RE = re.compile(r"^[A-Z0-9]{10}$")
_UUID_RE = re.compile(
    r"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
)


def _metadata(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise ValueError(f"IPA metadata file missing: {path}")
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"invalid IPA metadata line: {raw!r}")
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not key or key in values:
            raise ValueError(f"duplicate/empty IPA metadata key: {key!r}")
        values[key] = value
    required = {
        "bundle_id",
        "version_name",
        "build_number",
        "team_id",
        "profile_uuid",
        "ipa_sha256",
        "run_id",
        "source_sha",
    }
    missing = sorted(required - values.keys())
    if missing:
        raise ValueError("missing IPA metadata keys: " + ", ".join(missing))
    return values


def _sha256(path: Path) -> str:
    if not path.is_file() or path.stat().st_size <= 0:
        raise ValueError(f"IPA missing/empty: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def _sidecar(path: Path) -> str:
    if not path.is_file():
        raise ValueError(f"IPA SHA-256 sidecar missing: {path}")
    parts = path.read_text(encoding="utf-8").strip().split()
    if not parts:
        raise ValueError("IPA SHA-256 sidecar is empty")
    value = parts[0].upper()
    if not _SHA256_RE.fullmatch(value):
        raise ValueError("invalid IPA SHA-256 sidecar")
    return value


def _info_plist(ipa: Path) -> dict[str, object]:
    try:
        with zipfile.ZipFile(ipa) as archive:
            candidates = [
                name
                for name in archive.namelist()
                if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name)
            ]
            if len(candidates) != 1:
                raise ValueError(
                    f"IPA must contain exactly one app Info.plist, found {len(candidates)}"
                )
            return plistlib.loads(archive.read(candidates[0]))
    except zipfile.BadZipFile as error:
        raise ValueError(f"IPA is not a valid zip archive: {error}") from error


def verify(
    *,
    ipa: Path,
    metadata_path: Path,
    sha256_path: Path,
    expected_bundle_id: str,
    expected_run_id: str,
    actual_team_id: str,
    actual_profile_uuid: str,
) -> dict[str, str]:
    metadata = _metadata(metadata_path)
    actual_hash = _sha256(ipa)
    if actual_hash != _sidecar(sha256_path):
        raise ValueError("IPA SHA-256 does not match sidecar")

    metadata_hash = metadata["ipa_sha256"].upper()
    if not _SHA256_RE.fullmatch(metadata_hash) or metadata_hash != actual_hash:
        raise ValueError("IPA SHA-256 does not match release metadata")

    if metadata["bundle_id"] != expected_bundle_id:
        raise ValueError("IPA bundle ID metadata does not match expected bundle")
    if metadata["run_id"] != str(expected_run_id):
        raise ValueError("IPA run ID does not match selected archive run")
    if not _SOURCE_SHA_RE.fullmatch(metadata["source_sha"]):
        raise ValueError("invalid source SHA in IPA metadata")

    team_id = metadata["team_id"].upper()
    if not _TEAM_RE.fullmatch(team_id):
        raise ValueError("invalid team ID in IPA metadata")
    if actual_team_id.upper() != team_id:
        raise ValueError("signed app team ID does not match IPA metadata")

    profile_uuid = metadata["profile_uuid"].upper()
    if not _UUID_RE.fullmatch(profile_uuid):
        raise ValueError("invalid profile UUID in IPA metadata")
    if actual_profile_uuid.upper() != profile_uuid:
        raise ValueError("embedded profile UUID does not match IPA metadata")

    version_name = validate_version_name(metadata["version_name"])
    build_number = validate_version_code(metadata["build_number"])

    info = _info_plist(ipa)
    if info.get("CFBundleIdentifier") != expected_bundle_id:
        raise ValueError("IPA Info.plist bundle ID mismatch")
    if str(info.get("CFBundleShortVersionString", "")) != version_name:
        raise ValueError("IPA Info.plist versionName mismatch")
    if str(info.get("CFBundleVersion", "")) != str(build_number):
        raise ValueError("IPA Info.plist build number mismatch")

    return {
        "bundle_id": expected_bundle_id,
        "version_name": version_name,
        "build_number": str(build_number),
        "team_id": team_id,
        "profile_uuid": profile_uuid,
        "ipa_sha256": actual_hash,
        "source_sha": metadata["source_sha"],
        "run_id": metadata["run_id"],
    }


def self_test() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        ipa = root / "Zync.ipa"
        info = {
            "CFBundleIdentifier": "com.gmail.gentle3f.myproject",
            "CFBundleShortVersionString": "1.0.1",
            "CFBundleVersion": "7",
        }
        with zipfile.ZipFile(ipa, "w") as archive:
            archive.writestr(
                "Payload/Runner.app/Info.plist",
                plistlib.dumps(info),
            )
        digest = _sha256(ipa)
        metadata = root / "Zync-build.txt"
        metadata.write_text(
            "\n".join(
                [
                    "bundle_id=com.gmail.gentle3f.myproject",
                    "version_name=1.0.1",
                    "build_number=7",
                    "team_id=A1B2C3D4E5",
                    "profile_uuid=12345678-1234-4ABC-9DEF-1234567890AB",
                    f"ipa_sha256={digest}",
                    "run_id=12345",
                    "source_sha=" + "c" * 40,
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        sidecar = root / "Zync.sha256.txt"
        sidecar.write_text(f"{digest}  Zync.ipa\n", encoding="utf-8")

        result = verify(
            ipa=ipa,
            metadata_path=metadata,
            sha256_path=sidecar,
            expected_bundle_id="com.gmail.gentle3f.myproject",
            expected_run_id="12345",
            actual_team_id="A1B2C3D4E5",
            actual_profile_uuid="12345678-1234-4ABC-9DEF-1234567890AB",
        )
        assert result["version_name"] == "1.0.1"
        assert result["build_number"] == "7"

        try:
            verify(
                ipa=ipa,
                metadata_path=metadata,
                sha256_path=sidecar,
                expected_bundle_id="com.gmail.gentle3f.myproject",
                expected_run_id="12345",
                actual_team_id="A1B2C3D4E5",
                actual_profile_uuid="AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA",
            )
        except ValueError as error:
            assert "profile UUID" in str(error)
        else:
            raise AssertionError("profile UUID mismatch was not rejected")

    print("Zync signed-IPA provenance verifier self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--ipa")
    parser.add_argument("--metadata")
    parser.add_argument("--sha256-file")
    parser.add_argument("--expected-bundle-id")
    parser.add_argument("--expected-run-id")
    parser.add_argument("--actual-team-id")
    parser.add_argument("--actual-profile-uuid")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    required = {
        "--ipa": args.ipa,
        "--metadata": args.metadata,
        "--sha256-file": args.sha256_file,
        "--expected-bundle-id": args.expected_bundle_id,
        "--expected-run-id": args.expected_run_id,
        "--actual-team-id": args.actual_team_id,
        "--actual-profile-uuid": args.actual_profile_uuid,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        parser.error("missing required arguments: " + ", ".join(missing))

    try:
        result = verify(
            ipa=Path(args.ipa),
            metadata_path=Path(args.metadata),
            sha256_path=Path(args.sha256_file),
            expected_bundle_id=args.expected_bundle_id,
            expected_run_id=args.expected_run_id,
            actual_team_id=args.actual_team_id,
            actual_profile_uuid=args.actual_profile_uuid,
        )
    except ValueError as error:
        parser.exit(1, f"Signed IPA verification failed: {error}\n")

    print(
        "Signed IPA provenance verified: "
        f"bundle={result['bundle_id']} "
        f"version={result['version_name']}+{result['build_number']} "
        f"team={result['team_id']} "
        f"profile={result['profile_uuid']} "
        f"sha256={result['ipa_sha256']}"
    )


if __name__ == "__main__":
    main()
