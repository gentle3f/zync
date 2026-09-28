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

import re
import sys
import tempfile
from pathlib import Path


KTS_IMPORTS = """import java.io.FileInputStream
import java.util.Properties

"""

KTS_PROPERTIES = """val zyncKeystoreProperties = Properties()
val zyncKeystorePropertiesFile = rootProject.file("key.properties")
if (!zyncKeystorePropertiesFile.exists()) {
    throw org.gradle.api.GradleException("Missing android/key.properties for Zync release signing")
}
zyncKeystoreProperties.load(FileInputStream(zyncKeystorePropertiesFile))

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
    # Flutter/AGP 9 exposes a top-level Gradle `java` extension that can shadow
    # the JVM package root in Kotlin DSL. Use explicit imports rather than
    # java.util/java.io references so generated wrappers compile on current
    # Flutter stable. Imports are valid before the plugins block.
    text = text.replace("java.util.Properties()", "Properties()")
    text = text.replace("java.io.FileInputStream(", "FileInputStream(")
    if "import java.util.Properties" not in text:
        text = KTS_IMPORTS + text

    if 'create("zyncRelease")' in text:
        return text
    if "android {" not in text:
        raise ValueError("Could not find android block in build.gradle.kts")
    if 'signingConfig = signingConfigs.getByName("debug")' not in text:
        raise ValueError("Could not find Flutter template debug release signing line")

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


def normalize_key_properties(path: Path) -> None:
    """Make storeFile safe for Java Properties + Gradle on Windows.

    Java Properties treats backslashes as escape characters. A raw Windows path
    written with backslashes is therefore corrupted when Gradle loads
    key.properties. Forward slashes are accepted by Java/Gradle on Windows and
    preserve the absolute path.
    """
    if not path.exists():
        return

    raw_bytes = path.read_bytes()
    had_bom = raw_bytes.startswith(b"\xef\xbb\xbf")
    lines = raw_bytes.decode("utf-8-sig").splitlines()
    changed = had_bom
    output: list[str] = []
    for raw in lines:
        if raw.startswith("storeFile="):
            key, value = raw.split("=", 1)
            value = value.strip()
            if re.match(r"^[A-Za-z]:[\\/]", value) and "\\" in value:
                value = value.replace("\\", "/")
                changed = True
            output.append(f"{key}={value}")
        else:
            output.append(raw)

    if changed:
        path.write_text("\n".join(output) + "\n", encoding="utf-8")


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

    raw_store_file = values["storeFile"]
    if "\\" in raw_store_file:
        raise SystemExit(
            "storeFile must use forward slashes in key.properties "
            "(for example C:/Users/.../zync-qa.jks); "
            "Java properties treat backslashes as escapes"
        )

    store_file = Path(raw_store_file)
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
    properties_path = android / "key.properties"
    normalize_key_properties(properties_path)
    validate_key_properties(properties_path)
    path, flavor = gradle_file(root)
    original = path.read_text(encoding="utf-8")
    patched = patch_kts(original) if flavor == "kts" else patch_groovy(original)
    path.write_text(patched, encoding="utf-8")
    print(f"Configured Zync release signing: {path}")


def self_test() -> None:
    kts = """plugins { id(\"com.android.application\") }\nandroid {\n    buildTypes {\n        release {\n            signingConfig = signingConfigs.getByName(\"debug\")\n        }\n    }\n}\n"""
    patched_kts = patch_kts(kts)
    assert patched_kts.startswith("import java.io.FileInputStream\n")
    assert "import java.util.Properties" in patched_kts
    assert "java.util.Properties()" not in patched_kts
    assert "java.io.FileInputStream(" not in patched_kts
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

    with tempfile.TemporaryDirectory() as tmp:
        properties = Path(tmp) / "key.properties"
        properties.write_bytes(
            b"\xef\xbb\xbfstorePassword=test\n"
            b"keyPassword=test\n"
            b"keyAlias=zyncQa\n"
            b"storeFile=C:\\Users\\FUJITSU\\.zync\\qa-signing\\zync-qa.jks\n"
        )
        normalize_key_properties(properties)
        normalized = properties.read_text(encoding="utf-8")
        assert not properties.read_bytes().startswith(b"\xef\xbb\xbf")
        assert (
            "storeFile=C:/Users/FUJITSU/.zync/qa-signing/zync-qa.jks"
            in normalized
        )

        bom_forward = Path(tmp) / "key-forward.properties"
        bom_forward.write_bytes(
            b"\xef\xbb\xbfstorePassword=test\n"
            b"keyPassword=test\n"
            b"keyAlias=zyncQa\n"
            b"storeFile=C:/Users/FUJITSU/.zync/qa-signing/zync-qa.jks\n"
        )
        normalize_key_properties(bom_forward)
        assert not bom_forward.read_bytes().startswith(b"\xef\xbb\xbf")
        assert "storePassword=test" in bom_forward.read_text(encoding="utf-8")

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
