#!/usr/bin/env python3
"""Generate a disposable Flutter native wrapper from the source-only mobile tree.

The repository intentionally keeps Flutter business/UI source separate from
platform-generated wrappers. This tool provides one reproducible entry point for
Android and iOS and, critically, copies the complete asset bundle as well as
lib/test/config files.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import time
from pathlib import Path


def remove_tree(path: Path) -> None:
    if not path.exists():
        return
    last_error: OSError | None = None
    for attempt in range(6):
        try:
            shutil.rmtree(path)
            return
        except OSError as error:
            last_error = error
            time.sleep(0.15 * (attempt + 1))
    if last_error is not None:
        raise last_error


def copy_tree(source: Path, target: Path) -> None:
    if target.exists():
        remove_tree(target)
    if source.exists():
        shutil.copytree(source, target)


def generate(*, source: Path, output: Path, platform: str, org: str, project_name: str) -> None:
    source = source.resolve()
    output = output.resolve()
    if output.exists():
        remove_tree(output)

    flutter = shutil.which("flutter") or shutil.which("flutter.bat")
    if flutter is None:
        raise SystemExit("Flutter executable not found on PATH")
    flutter_args = [
        flutter,
        "create",
        f"--platforms={platform}",
        "--org",
        org,
        "--project-name",
        project_name,
        str(output),
    ]
    command = ["cmd.exe", "/d", "/c", *flutter_args] if os.name == "nt" else flutter_args
    subprocess.run(command, check=True)

    copy_tree(source / "lib", output / "lib")
    copy_tree(source / "test", output / "test")
    copy_tree(source / "assets", output / "assets")

    for name in ("pubspec.yaml", "l10n.yaml"):
        src = source / name
        if not src.exists():
            raise SystemExit(f"Required mobile source file missing: {src}")
        shutil.copy2(src, output / name)

    print(f"Generated Zync {platform} wrapper")
    print(f"source={source}")
    print(f"output={output}")
    print(f"assets={(output / 'assets').exists()}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("platform", choices=("android", "ios"))
    parser.add_argument("output")
    parser.add_argument(
        "--source",
        default=str(Path(__file__).resolve().parents[1]),
    )
    parser.add_argument("--org", default="com.gmail.gentle3f")
    parser.add_argument("--project-name", default="myproject")
    args = parser.parse_args()

    generate(
        source=Path(args.source),
        output=Path(args.output),
        platform=args.platform,
        org=args.org,
        project_name=args.project_name,
    )


if __name__ == "__main__":
    main()
