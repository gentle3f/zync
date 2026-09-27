#!/usr/bin/env python3
"""Apply Sign in with Apple capability to a generated Zync iOS wrapper.

The repository intentionally does not keep a long-lived ios/ tree. This tool
makes the Apple entitlement reproducible whenever a disposable wrapper is
created.
"""

from __future__ import annotations

import argparse
import plistlib
import re
from pathlib import Path


DEFAULT_BUNDLE_ID = "com.gmail.gentle3f.myproject"


def write_entitlements(path: Path) -> None:
    payload = {
        "com.apple.developer.applesignin": ["Default"],
    }
    with path.open("wb") as handle:
        plistlib.dump(payload, handle, sort_keys=False)


def runner_target_id(project: str) -> str:
    match = re.search(
        r"(?m)^\s*([A-F0-9]{24}) /\* Runner \*/ = \{\n"
        r"\s*isa = PBXNativeTarget;\n"
        r"\s*buildConfigurationList = [^\n]+PBXNativeTarget \"Runner\"",
        project,
    )
    if not match:
        raise SystemExit("Could not locate Runner PBXNativeTarget")
    return match.group(1)


def patch_build_settings(project: str, bundle_id: str) -> str:
    pattern = re.compile(
        rf"(?m)^(\s*)PRODUCT_BUNDLE_IDENTIFIER = {re.escape(bundle_id)};$"
    )

    def replace(match: re.Match[str]) -> str:
        indent = match.group(1)
        return (
            f"{indent}CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n"
            f"{match.group(0)}"
        )

    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" in project:
        return project

    project, count = pattern.subn(replace, project)
    if count != 3:
        raise SystemExit(
            f"Expected 3 Runner build configurations, patched {count}"
        )
    return project


def patch_system_capability(project: str, target_id: str) -> str:
    target_pattern = re.compile(
        rf"({re.escape(target_id)} = \{{\n"
        r"\s*CreatedOnToolsVersion = [^;]+;\n"
        r"(?:\s*LastSwiftMigration = [^;]+;\n)?)"
    )
    match = target_pattern.search(project)
    if not match:
        raise SystemExit("Could not locate Runner TargetAttributes")

    block_start = match.group(1)
    if "com.apple.SignInWithApple" in project[
        match.start() : min(len(project), match.start() + 700)
    ]:
        return project

    indent_match = re.search(r"(?m)^(\s*)CreatedOnToolsVersion", block_start)
    if not indent_match:
        raise SystemExit("Could not infer TargetAttributes indentation")
    indent = indent_match.group(1)
    capability = (
        f"{indent}SystemCapabilities = {{\n"
        f"{indent}\tcom.apple.SignInWithApple = {{\n"
        f"{indent}\t\tenabled = 1;\n"
        f"{indent}\t}};\n"
        f"{indent}}};\n"
    )
    replacement = block_start + capability
    return project[: match.start()] + replacement + project[match.end() :]


def configure(root: Path, bundle_id: str) -> None:
    project_path = root / "ios/Runner.xcodeproj/project.pbxproj"
    entitlements_path = root / "ios/Runner/Runner.entitlements"
    if not project_path.exists():
        raise SystemExit(f"Generated iOS wrapper not found under {root}")

    project = project_path.read_text(encoding="utf-8")
    target_id = runner_target_id(project)
    project = patch_build_settings(project, bundle_id)
    project = patch_system_capability(project, target_id)

    write_entitlements(entitlements_path)
    project_path.write_text(project, encoding="utf-8")

    print("Applied Zync Sign in with Apple capability")
    print(f"bundle_id={bundle_id}")
    print(f"target_id={target_id}")
    print(f"entitlements={entitlements_path}")


def check(root: Path) -> None:
    project_path = root / "ios/Runner.xcodeproj/project.pbxproj"
    entitlements_path = root / "ios/Runner/Runner.entitlements"
    if not project_path.exists() or not entitlements_path.exists():
        raise SystemExit("Generated iOS Apple capability files are incomplete")

    project = project_path.read_text(encoding="utf-8")
    if project.count(
        "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;"
    ) != 3:
        raise SystemExit("Runner entitlements are not attached to all build configs")
    if "com.apple.SignInWithApple" not in project:
        raise SystemExit("Runner target is missing Sign in with Apple capability")

    with entitlements_path.open("rb") as handle:
        entitlements = plistlib.load(handle)
    if entitlements.get("com.apple.developer.applesignin") != ["Default"]:
        raise SystemExit("Sign in with Apple entitlement is invalid")

    print("Zync iOS Apple capability check passed")


def self_test() -> None:
    sample = """
\t\t97C146ED1CF9000F007C117D /* Runner */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;
\t\t};
\t\t\t\t97C146ED1CF9000F007C117D = {
\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;
\t\t\t\t\tLastSwiftMigration = 1100;
\t\t\t\t};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gmail.gentle3f.myproject;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gmail.gentle3f.myproject;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.gmail.gentle3f.myproject;
"""
    target = runner_target_id(sample)
    assert target == "97C146ED1CF9000F007C117D"
    patched = patch_build_settings(sample, DEFAULT_BUNDLE_ID)
    patched = patch_system_capability(patched, target)
    assert patched.count("CODE_SIGN_ENTITLEMENTS") == 3
    assert "com.apple.SignInWithApple" in patched
    print("Zync iOS Apple capability self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build_app")
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    root = Path(args.root)
    if args.check:
        check(root)
        return
    configure(root, args.bundle_id)


if __name__ == "__main__":
    main()
