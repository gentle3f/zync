#!/usr/bin/env python3
"""Configure a generated Flutter Android wrapper for Zync release signing.

The real keystore and passwords are intentionally never source-controlled.
GitHub Actions writes android/key.properties and the keystore into the ephemeral
runner workspace, then this script patches the generated Flutter Gradle file to
use a dedicated `zyncRelease` signing config.

Modes:
- `--self-test` validates the transform fixtures without secrets.
- `--check-template <root>` validates that the current generated Flutter wrapper
  still matches the transform, without writing files or requiring secrets.
- `<root>` performs the real signing-config patch after key.properties exists.
"""

from __future__ import annotations

import sys
from pathlib import Path


KTS_PROPERTIES = """val zyncKeystoreProperties = java.util.Properties()
val zyncKeystorePropertiesFile = rootProject.file("key.properties")
if (!zyncKeystorePropertiesFile.exists()) {
    throw org.gradle.api.GradleException("Missing android/key.properties for Zync release signing")
}
zyncKeystoreProperties.load(java.io.FileInputStream(zyncKeystorePropertiesFile))

"""

KTS_SIGNING = """
    signingConfigs {
        create("zyncRelease") {
            keyAlias = zyncKeystoreProperties["keyAlias"] as String
            keyPassword = zyncKeystoreProperties["keyPassword"] as String
            storeFile = file(zyncKeystoreProperties["storeFile"] as String)
            storePassword = zyncKeystoreProperties["storePassword"] as String
        }
    }

"""

GROOVY_PROPERTIES = """def zyncKeystoreProperties = new java.util.Properties()
def zyncKeystorePropertiesFile = rootProject.file('key.properties')
if (!zyncKeystorePropertiesFile.exists()) {
    throw new org.gradle.api.GradleException('Missing android/key.properties for Zync release signing')
}
zyncKeystoreProperties.load(new java.io.FileInputStream(zyncKeystorePropertiesFile))

"""

GROOVY_SIGNING = """
    signingConfigs {
        zyncRelease {
            keyAlias zyncKeystoreProperties['keyAlias']
            keyPassword zyncKeystoreProperties['keyPassword']
            storeFile file(zyncKeystoreProperties['storeFile'])
            storePassword zyncKeystoreProperties['storePassword']
        }
    }

"""

REQUIRED_KEYS = {"storePassword", "keyPassword", "keyAlias", "storeFile"}


def patch_kts(text: str) -> str:
    if 'create("zyncRelease")' in text:
        return text
    if "android {" not in text:
        raise ValueError("Could not find android block in build.gradle.kts")
    if 'signingConfig = signingConfigs.getByName("debug")' not in text:
        raise ValueError("Could not find Flutter template debug release signing line")

    # Keep Gradle's plugins block first. Arbitrary top-level statements before
    # plugins are rejected, so signing properties are inserted just before the
    # android block instead.
    text = text.replace("android {", KTS_PROPERTIES + "android {\n" + KTS_SIGNING, 1)
    text = text.replace(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = signingConfigs.getByName("zyncRelease")',
        1,
    )
    return text


def patch_groovy(text: str) -> str:
    if "zyncRelease" in text:
        return text
    if "android {" not in text:
        raise ValueError("Could not find android block in build.gradle")
    if "signingConfig signingConfigs.debug" not in text:
        raise ValueError("Could not find Flutter template debug release signing line")

    text = text.replace("android {", GROOVY_PROPERTIES + "android {\n" + GROOVY_SIGNING, 1)
    text = text.replace(
        "signingConfig signingConfigs.debug",
        "signingConfig signingConfigs.zyncRelease",
        1,
    )
    return text


def gradle_file(root: Path) -> tuple[Path, str]:
    android = root / "android"
    kts = android / "app/build.gradle.kts"
    groovy = android / "app/build.gradle"
    if kts.exists():
        return kts, "kts"
    if groovy.exists():
        return groovy, "groovy"
    raise SystemExit("No Android app Gradle file found")


def validate_key_properties(path: Path) -> None:
    if not path.exists():
        raise SystemExit(f"Signing properties not found: {path}")

    values: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()

    missing = sorted(key for key in REQUIRED_KEYS if not values.get(key))
    if missing:
        raise SystemExit("Missing signing properties: " + ", ".join(missing))

    store_file = Path(values["storeFile"])
    if not store_file.is_absolute():
        store_file = path.parent / store_file
    if not store_file.exists():
        raise SystemExit(f"Keystore file not found: {store_file}")


def check_template(root: Path) -> None:
    path, flavor = gradle_file(root)
    original = path.read_text(encoding="utf-8")
    patched = patch_kts(original) if flavor == "kts" else patch_groovy(original)
    if patched == original:
        raise SystemExit("Signing transform made no change to generated Gradle template")
    if "zyncRelease" not in patched:
        raise SystemExit("Signing transform did not create zyncRelease config")
    print(f"Zync signing transform matches generated template: {path}")


def configure(root: Path) -> None:
    android = root / "android"
    validate_key_properties(android / "key.properties")
    path, flavor = gradle_file(root)
    original = path.read_text(encoding="utf-8")
    patched = patch_kts(original) if flavor == "kts" else patch_groovy(original)
    path.write_text(patched, encoding="utf-8")
    print(f"Configured Zync release signing: {path}")


def self_test() -> None:
    kts = """plugins { id(\"com.android.application\") }\nandroid {\n    buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName(\"debug\")\n        }\n    }\n}\n"""
    patched_kts = patch_kts(kts)
    assert patched_kts.startswith('plugins {')
    assert 'create("zyncRelease")' in patched_kts
    assert 'signingConfig = signingConfigs.getByName("zyncRelease")' in patched_kts
    assert 'signingConfig = signingConfigs.getByName("debug")' not in patched_kts
    assert patched_kts.index("zyncKeystoreProperties") < patched_kts.index("android {")

    groovy = """plugins { id 'com.android.application' }\nandroid {\n    buildTypes {\n        release {\n            signingConfig signingConfigs.debug\n        }\n    }\n}\n"""
    patched_groovy = patch_groovy(groovy)
    assert patched_groovy.startswith('plugins {')
    assert "zyncRelease" in patched_groovy
    assert "signingConfig signingConfigs.zyncRelease" in patched_groovy
    assert "signingConfig signingConfigs.debug" not in patched_groovy
    assert patched_groovy.index("zyncKeystoreProperties") < patched_groovy.index("android {")

    print("Zync signing-config helper self-test passed")


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        self_test()
        return
    if len(sys.argv) > 1 and sys.argv[1] == "--check-template":
        root = Path(sys.argv[2] if len(sys.argv) > 2 else "build_app")
        check_template(root)
        return
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "build_app")
    configure(root)


if __name__ == "__main__":
    main()
