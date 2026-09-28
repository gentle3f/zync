#!/usr/bin/env python3
"""Verify Zync signed-AAB provenance metadata.

This does not replace JAR signature verification. Workflows must run
`jarsigner -verify` first, then pass the signer SHA-1 extracted from the AAB
into this helper. The helper verifies the artifact hash, signer fingerprint,
package/run provenance and sidecar consistency.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import tempfile
from pathlib import Path


_SHA1_RE = re.compile(r"^[0-9A-F]{40}$")
_SHA256_RE = re.compile(r"^[0-9A-F]{64}$")
_SOURCE_SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")


def normalize_sha1(value: str) -> str:
    compact = value.replace(":", "").strip().upper()
    if not _SHA1_RE.fullmatch(compact):
        raise ValueError("invalid signer SHA-1")
    return compact


def normalize_sha256(value: str) -> str:
    compact = value.strip().upper()
    if not _SHA256_RE.fullmatch(compact):
        raise ValueError("invalid AAB SHA-256")
    return compact


def read_metadata(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise ValueError(f"metadata file missing: {path}")
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"invalid metadata line: {raw!r}")
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not key or key in values:
            raise ValueError(f"duplicate/empty metadata key: {key!r}")
        values[key] = value
    required = {
        "package",
        "signer_sha1",
        "aab_sha256",
        "run_id",
        "source_sha",
        "version",
    }
    missing = sorted(required - values.keys())
    if missing:
        raise ValueError("missing metadata keys: " + ", ".join(missing))
    return values


def read_sha256_sidecar(path: Path) -> str:
    if not path.is_file():
        raise ValueError(f"SHA-256 sidecar missing: {path}")
    first = path.read_text(encoding="utf-8").strip().split()
    if not first:
        raise ValueError("SHA-256 sidecar is empty")
    return normalize_sha256(first[0])


def file_sha256(path: Path) -> str:
    if not path.is_file() or path.stat().st_size <= 0:
        raise ValueError(f"AAB missing/empty: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def verify(
    *,
    aab: Path,
    metadata_path: Path,
    sha256_path: Path,
    expected_package: str,
    expected_run_id: str,
    actual_signer_sha1: str,
) -> dict[str, str]:
    metadata = read_metadata(metadata_path)
    actual_hash = file_sha256(aab)
    sidecar_hash = read_sha256_sidecar(sha256_path)
    metadata_hash = normalize_sha256(metadata["aab_sha256"])

    if actual_hash != sidecar_hash or actual_hash != metadata_hash:
        raise ValueError("AAB SHA-256 does not match metadata/sidecar")

    actual_signer = normalize_sha1(actual_signer_sha1)
    metadata_signer = normalize_sha1(metadata["signer_sha1"])
    if actual_signer != metadata_signer:
        raise ValueError("AAB signer SHA-1 does not match release metadata")

    if metadata["package"] != expected_package:
        raise ValueError(
            f"package mismatch: {metadata['package']} != {expected_package}"
        )

    if metadata["run_id"] != str(expected_run_id):
        raise ValueError(
            f"run-id mismatch: {metadata['run_id']} != {expected_run_id}"
        )

    if not _SOURCE_SHA_RE.fullmatch(metadata["source_sha"]):
        raise ValueError("invalid source SHA in metadata")

    if not metadata["version"]:
        raise ValueError("release version is empty")

    return {
        "package": metadata["package"],
        "signer_sha1": ":".join(
            actual_signer[i : i + 2] for i in range(0, 40, 2)
        ),
        "aab_sha256": actual_hash,
        "run_id": metadata["run_id"],
        "source_sha": metadata["source_sha"],
        "version": metadata["version"],
    }


def self_test() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        aab = root / "app-release.aab"
        aab.write_bytes(b"zync-aab-fixture")
        digest = file_sha256(aab)
        signer = "AA" * 20
        metadata = root / "app-release-build.txt"
        metadata.write_text(
            "\n".join(
                [
                    "package=com.gmail.gentle3f.myproject",
                    f"signer_sha1={signer}",
                    f"aab_sha256={digest}",
                    "run_id=12345",
                    "source_sha=" + "b" * 40,
                    "version=1.0.0+6",
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        sidecar = root / "app-release.sha256.txt"
        sidecar.write_text(
            f"{digest}  app-release.aab\n",
            encoding="utf-8",
        )

        result = verify(
            aab=aab,
            metadata_path=metadata,
            sha256_path=sidecar,
            expected_package="com.gmail.gentle3f.myproject",
            expected_run_id="12345",
            actual_signer_sha1=signer,
        )
        assert result["aab_sha256"] == digest

        try:
            verify(
                aab=aab,
                metadata_path=metadata,
                sha256_path=sidecar,
                expected_package="com.example.wrong",
                expected_run_id="12345",
                actual_signer_sha1=signer,
            )
        except ValueError as error:
            assert "package mismatch" in str(error)
        else:
            raise AssertionError("package mismatch was not rejected")

        metadata.write_text(
            metadata.read_text(encoding="utf-8").replace(
                f"aab_sha256={digest}",
                "aab_sha256=" + "0" * 64,
            ),
            encoding="utf-8",
        )
        try:
            verify(
                aab=aab,
                metadata_path=metadata,
                sha256_path=sidecar,
                expected_package="com.gmail.gentle3f.myproject",
                expected_run_id="12345",
                actual_signer_sha1=signer,
            )
        except ValueError as error:
            assert "SHA-256" in str(error)
        else:
            raise AssertionError("hash mismatch was not rejected")

    print("Zync signed-AAB verifier self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--aab")
    parser.add_argument("--metadata")
    parser.add_argument("--sha256-file")
    parser.add_argument("--expected-package")
    parser.add_argument("--expected-run-id")
    parser.add_argument("--actual-signer-sha1")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    required = {
        "--aab": args.aab,
        "--metadata": args.metadata,
        "--sha256-file": args.sha256_file,
        "--expected-package": args.expected_package,
        "--expected-run-id": args.expected_run_id,
        "--actual-signer-sha1": args.actual_signer_sha1,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        parser.error("missing required arguments: " + ", ".join(missing))

    try:
        result = verify(
            aab=Path(args.aab),
            metadata_path=Path(args.metadata),
            sha256_path=Path(args.sha256_file),
            expected_package=args.expected_package,
            expected_run_id=args.expected_run_id,
            actual_signer_sha1=args.actual_signer_sha1,
        )
    except ValueError as error:
        parser.exit(
            1,
            "Signed AAB verification failed: " + str(error) + "\n",
        )

    print(
        "Signed AAB provenance verified: "
        f"package={result['package']} "
        f"run_id={result['run_id']} "
        f"signer_sha1={result['signer_sha1']} "
        f"sha256={result['aab_sha256']}"
    )


if __name__ == "__main__":
    main()
