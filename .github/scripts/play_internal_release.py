#!/usr/bin/env python3
"""Publish a pre-signed Zync AAB to Google Play Internal Testing only.

This script never builds or signs an AAB and never generates a signing key.
It consumes an already-signed `.aab` produced by the existing
`zync-v1-signed-release.yml` workflow and uploads it through the Google Play
Android Publisher API, restricted to the `internal` testing track.

Safety properties (enforced in code, not only by workflow config):
- `--track` must be exactly `internal`. Any other value is a hard failure.
- `--package` must be exactly `com.gmail.gentle3f.myproject`.
- The AAB must exist, be non-empty, and carry a valid JAR signature
  (`jarsigner -verify -strict`) before any Play API call is made.
- The credentials file path is read from `GOOGLE_APPLICATION_CREDENTIALS` (or
  `--credentials`); its contents are never printed, logged, or returned.
- A Play "edit" is committed only after upload + track update + validate all
  succeed. Any failure before commit triggers `edits().delete()` so no
  partial state is left behind on Google Play.

Modes:
- `--self-test` validates the guard logic (track/package/signature checks)
  against local fixtures only. It makes no network calls and needs no
  credentials. This is the mode CI and local validation should use.
- Without `--self-test`, the script performs the real Play API call and
  requires `--aab`, `--package`, `--track internal`, and valid credentials.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ALLOWED_TRACK = "internal"
EXPECTED_PACKAGE = "com.gmail.gentle3f.myproject"


class GuardError(Exception):
    """Raised when a safety guard rejects the requested release."""


def require_internal_track(track: str) -> None:
    if track != ALLOWED_TRACK:
        raise GuardError(
            f"Refusing to publish: track must be exactly '{ALLOWED_TRACK}', got '{track}'. "
            "This tool never publishes to production, beta, alpha, or any other track."
        )


def require_expected_package(package_name: str) -> None:
    if package_name != EXPECTED_PACKAGE:
        raise GuardError(
            f"Refusing to publish: package must be exactly '{EXPECTED_PACKAGE}', got '{package_name}'."
        )


def require_signed_aab(aab_path: Path) -> None:
    if not aab_path.is_file() or aab_path.stat().st_size == 0:
        raise GuardError(f"No signed AAB available at {aab_path}. Refusing to publish an empty/missing bundle.")

    try:
        with zipfile.ZipFile(aab_path) as archive:
            names = archive.namelist()
    except zipfile.BadZipFile as exc:
        raise GuardError(f"{aab_path} is not a valid AAB/zip archive: {exc}") from exc

    if not any(name.startswith("META-INF/") and (name.endswith(".RSA") or name.endswith(".EC") or name.endswith(".DSA")) for name in names):
        raise GuardError(f"{aab_path} has no META-INF signature block. Refusing to publish an unsigned bundle.")

    try:
        subprocess.run(
            ["jarsigner", "-verify", "-strict", str(aab_path)],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise GuardError("jarsigner is not available on this runner; cannot verify AAB signature.") from exc
    except subprocess.CalledProcessError as exc:
        raise GuardError(f"jarsigner signature verification failed for {aab_path}: {exc.stderr.strip()}") from exc


def require_credentials_file(path: Path) -> None:
    if not path.is_file() or path.stat().st_size == 0:
        raise GuardError(
            f"No Google Play service-account credentials file at {path}. "
            "Set GOOGLE_APPLICATION_CREDENTIALS or pass --credentials."
        )


def publish_internal_release(
    *,
    package_name: str,
    aab_path: Path,
    credentials_path: Path,
    release_notes: str,
    dry_run: bool = False,
) -> None:
    require_expected_package(package_name)
    require_internal_track(ALLOWED_TRACK)
    require_signed_aab(aab_path)
    require_credentials_file(credentials_path)

    if dry_run:
        print("[dry-run] All pre-flight guards passed. No Play API call made.")
        return

    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload

    scopes = ["https://www.googleapis.com/auth/androidpublisher"]
    credentials = service_account.Credentials.from_service_account_file(str(credentials_path), scopes=scopes)
    service = build("androidpublisher", "v3", credentials=credentials)

    edit_id = service.edits().insert(packageName=package_name, body={}).execute()["id"]
    print(f"Opened Play edit for {package_name} (internal track only)")

    try:
        media = MediaFileUpload(str(aab_path), mimetype="application/octet-stream", resumable=True)
        bundle = service.edits().bundles().upload(
            packageName=package_name,
            editId=edit_id,
            media_body=media,
        ).execute()
        version_code = bundle["versionCode"]
        print(f"Uploaded AAB as versionCode {version_code}")

        service.edits().tracks().update(
            packageName=package_name,
            editId=edit_id,
            track=ALLOWED_TRACK,
            body={
                "track": ALLOWED_TRACK,
                "releases": [
                    {
                        "versionCodes": [str(version_code)],
                        "status": "completed",
                        "releaseNotes": [{"language": "en-US", "text": release_notes}],
                    }
                ],
            },
        ).execute()
        print(f"Updated '{ALLOWED_TRACK}' track with versionCode {version_code}")

        service.edits().validate(packageName=package_name, editId=edit_id).execute()
        print("Edit validated successfully")

        service.edits().commit(packageName=package_name, editId=edit_id).execute()
        print(f"Committed Play edit: versionCode {version_code} is now live on '{ALLOWED_TRACK}'")
    except Exception:
        print("A step before commit failed; abandoning the Play edit (no changes will be published)", file=sys.stderr)
        try:
            service.edits().delete(packageName=package_name, editId=edit_id).execute()
        except Exception as cleanup_exc:  # pragma: no cover - best-effort cleanup
            print(f"WARN: could not delete edit {edit_id} cleanly: {cleanup_exc}", file=sys.stderr)
        raise


def self_test() -> None:
    # Track guard: only "internal" may pass.
    require_internal_track("internal")
    for bad_track in ("production", "beta", "alpha", "rollout", "Internal", "internal "):
        try:
            require_internal_track(bad_track)
        except GuardError:
            pass
        else:
            raise AssertionError(f"require_internal_track must reject '{bad_track}'")

    # Package guard: only the exact Zync package may pass.
    require_expected_package(EXPECTED_PACKAGE)
    for bad_package in ("com.example.other", "com.gmail.gentle3f.myproject.debug", ""):
        try:
            require_expected_package(bad_package)
        except GuardError:
            pass
        else:
            raise AssertionError(f"require_expected_package must reject '{bad_package}'")

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)

        missing_aab = tmp_path / "missing.aab"
        try:
            require_signed_aab(missing_aab)
        except GuardError:
            pass
        else:
            raise AssertionError("require_signed_aab must reject a missing file")

        empty_aab = tmp_path / "empty.aab"
        empty_aab.write_bytes(b"")
        try:
            require_signed_aab(empty_aab)
        except GuardError:
            pass
        else:
            raise AssertionError("require_signed_aab must reject an empty file")

        unsigned_zip = tmp_path / "unsigned.aab"
        with zipfile.ZipFile(unsigned_zip, "w") as archive:
            archive.writestr("base/manifest/AndroidManifest.xml", b"stub")
        try:
            require_signed_aab(unsigned_zip)
        except GuardError:
            pass
        else:
            raise AssertionError("require_signed_aab must reject a zip with no META-INF signature block")

        missing_creds = tmp_path / "missing-creds.json"
        try:
            require_credentials_file(missing_creds)
        except GuardError:
            pass
        else:
            raise AssertionError("require_credentials_file must reject a missing credentials file")

        empty_creds = tmp_path / "empty-creds.json"
        empty_creds.write_bytes(b"")
        try:
            require_credentials_file(empty_creds)
        except GuardError:
            pass
        else:
            raise AssertionError("require_credentials_file must reject an empty credentials file")

        # A dry-run end-to-end call must fail fast on a bad track/package
        # combination without ever attempting network access.
        try:
            publish_internal_release(
                package_name="com.example.wrong",
                aab_path=unsigned_zip,
                credentials_path=empty_creds,
                release_notes="test",
                dry_run=True,
            )
        except GuardError:
            pass
        else:
            raise AssertionError("publish_internal_release(dry_run=True) must still enforce package guard")

    print("Zync Play internal-release guard self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="Run local guard tests only; no network calls, no credentials needed.")
    parser.add_argument("--dry-run", action="store_true", help="Run all guards but skip the actual Play API call.")
    parser.add_argument("--package", default=EXPECTED_PACKAGE)
    parser.add_argument("--track", default=ALLOWED_TRACK)
    parser.add_argument("--aab", type=Path)
    parser.add_argument("--credentials", type=Path, default=None)
    parser.add_argument("--release-notes", default="Internal testing build.")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    if args.aab is None:
        parser.error("--aab is required unless --self-test is given")

    credentials_path = args.credentials or Path(os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", ""))

    try:
        require_internal_track(args.track)
        publish_internal_release(
            package_name=args.package,
            aab_path=args.aab,
            credentials_path=credentials_path,
            release_notes=args.release_notes,
            dry_run=args.dry_run,
        )
    except GuardError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
