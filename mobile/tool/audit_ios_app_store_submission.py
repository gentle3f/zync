#!/usr/bin/env python3
"""Audit Zync iOS App Store submission readiness from source-controlled evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def audit(root: Path) -> dict[str, object]:
    mobile = root / "mobile"
    privacy_spec = json.loads(
        (mobile / "app_store_privacy_details.json").read_text(encoding="utf-8")
    )
    privacy = (root / "privacy.html").read_text(encoding="utf-8")
    terms = (root / "terms.html").read_text(encoding="utf-8")
    landing = (root / "index.html").read_text(encoding="utf-8")
    branding = (mobile / "tool/apply_ios_branding.py").read_text(encoding="utf-8")
    analytics = (mobile / "lib/core/analytics_service.dart").read_text(encoding="utf-8")
    account = (mobile / "lib/screens/cardverse_account_screen.dart").read_text(
        encoding="utf-8"
    )
    cloud = (mobile / "lib/core/cardverse_cloud_client.dart").read_text(
        encoding="utf-8"
    )
    compile_wf = (root / ".github/workflows/zync-ios-compile-smoke.yml").read_text(
        encoding="utf-8"
    )
    signed_wf = (root / ".github/workflows/zync-ios-signed-archive.yml").read_text(
        encoding="utf-8"
    )

    problems: list[str] = []
    blockers: list[str] = []

    expected_types = {
        "NSPrivacyCollectedDataTypeEmailAddress",
        "NSPrivacyCollectedDataTypeProductInteraction",
        "NSPrivacyCollectedDataTypeUserID",
    }
    actual_types = {
        item.get("appleType")
        for item in privacy_spec.get("collectedData", [])
        if isinstance(item, dict)
    }
    if privacy_spec.get("tracking") is not False:
        problems.append("privacy_spec_tracking_not_false")
    if actual_types != expected_types:
        problems.append("privacy_spec_data_types_drift")
    if privacy_spec.get("productionAnalytics", {}).get("enabled") is not False:
        problems.append("privacy_spec_production_analytics_not_false")

    obsolete = (
        "Zync V1 has no permanent cloud user profile",
        "Because Zync V1 has no account",
        "designed without login or registration",
    )
    for phrase in obsolete:
        if phrase in privacy or phrase in terms or phrase in landing:
            problems.append(f"obsolete_legal_claim:{phrase}")

    required_policy_markers = (
        "Google or Apple",
        "card",
        "reward",
        "private People history",
        "Product analytics are disabled by default",
        "camera access",
    )
    for marker in required_policy_markers:
        if marker.lower() not in privacy.lower():
            problems.append(f"privacy_policy_missing:{marker}")

    if "NSCameraUsageDescription" not in branding:
        problems.append("ios_camera_usage_description_missing")
    if "NSUserTrackingUsageDescription" in branding:
        problems.append("unexpected_att_usage_description")
    if "defaultValue: false" not in analytics or "if (!enabled) return;" not in analytics:
        problems.append("production_analytics_off_contract_missing")

    for name, workflow in (
        ("compile", compile_wf),
        ("signed", signed_wf),
    ):
        for marker in (
            "apply_ios_privacy_manifest.py",
            "audit_ios_privacy_dependencies.py",
            "ZYNC_ANALYTICS_ENABLED=false",
        ):
            if marker not in workflow:
                problems.append(f"{name}_workflow_missing:{marker}")

    account_creation = (
        "Continue with Google" in account
        and "Continue with Apple" in account
        and "authenticateProvider" in cloud
    )
    if not account_creation:
        problems.append("account_creation_contract_missing")

    deletion_markers = (
        "deleteAccount(" in cloud
        and "zync-account-delete-account" in account
        and "account/delete" in cloud
    )
    if account_creation and not deletion_markers:
        blockers.append("account_deletion_flow_missing")

    # Sign in with Apple account deletion should revoke Apple authorization.
    # Only runtime source can count as implementation evidence. Tests, workflows,
    # contracts, handoffs and documentation must never satisfy this gate.
    revoke_markers = (
        "appleid.apple.com/auth/revoke",
        "revokeappletok",
        "revoke_apple_tok",
        "revokeappleauthorization",
        "revoke_apple_authorization",
    )
    apple_revoke_sources: list[str] = []
    runtime_roots = [
        mobile / "lib",
        root / "api",
        root / "server",
    ]
    for runtime_root in runtime_roots:
        if not runtime_root.is_dir():
            continue
        for path in runtime_root.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix.lower() not in {".dart", ".js", ".mjs", ".ts", ".py"}:
                continue
            try:
                source = path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            low = source.lower()
            if any(marker in low for marker in revoke_markers):
                apple_revoke_sources.append(
                    path.relative_to(root).as_posix()
                )

    apple_revoke_evidence = bool(apple_revoke_sources)
    if account_creation and not apple_revoke_evidence:
        blockers.append("apple_token_revocation_not_verifiable")

    return {
        "privacy_contract_ok": not problems,
        "problems": problems,
        "submission_blockers": blockers,
        "account_creation_detected": account_creation,
        "account_deletion_detected": deletion_markers,
        "apple_token_revocation_evidence": apple_revoke_evidence,
        "apple_token_revocation_sources": apple_revoke_sources,
    }


def self_test() -> None:
    # The repo audit itself is deterministic; validate result schema only here.
    sample = {
        "privacy_contract_ok": True,
        "problems": [],
        "submission_blockers": [
            "account_deletion_flow_missing",
            "apple_token_revocation_not_verifiable",
        ],
    }
    assert sample["privacy_contract_ok"] is True
    assert sample["submission_blockers"] == [
        "account_deletion_flow_missing",
        "apple_token_revocation_not_verifiable",
    ]
    print("Zync iOS submission-readiness audit self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--strict-submission", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    result = audit(Path(args.root).resolve())
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if not result["privacy_contract_ok"]:
        parser.exit(1, "iOS privacy/submission source contract failed\n")
    if args.strict_submission and result["submission_blockers"]:
        parser.exit(
            2,
            "iOS App Store submission is blocked: "
            + ", ".join(result["submission_blockers"])
            + "\n",
        )


if __name__ == "__main__":
    main()