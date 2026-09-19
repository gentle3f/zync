#!/usr/bin/env python3
"""Apply Zync Android branding to a generated Flutter Android wrapper.

This repository intentionally generates the Android wrapper in CI so the legacy
Play package identity stays auditable. This script makes the brand/security layer
reproducible: app label, camera permission, secure-storage backup policy, SDK pins,
launcher icon and launch screen are all derived from source-controlled text assets.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


CREAM = "#FFFAF6"
ORANGE = "#FFFF6A21"
PLUM = "#FF6E5AE6"
INK = "#FF17181C"


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + "\n", encoding="utf-8")


def patch_manifest(manifest: Path) -> None:
    text = manifest.read_text(encoding="utf-8")
    if "android.permission.CAMERA" not in text:
        text = text.replace(
            "<application",
            '<uses-permission android:name="android.permission.CAMERA" />\n    <application',
            1,
        )
    text = re.sub(r'android:label="[^"]*"', 'android:label="Zync"', text, count=1)
    if "android:allowBackup=" in text:
        text = re.sub(
            r'android:allowBackup="[^"]*"',
            'android:allowBackup="false"',
            text,
            count=1,
        )
    else:
        text = text.replace(
            "<application",
            '<application\n        android:allowBackup="false"',
            1,
        )
    text = re.sub(r'android:icon="[^"]*"', 'android:icon="@mipmap/zync_launcher"', text, count=1)
    if "android:roundIcon=" not in text:
        text = text.replace(
            'android:icon="@mipmap/zync_launcher"',
            'android:icon="@mipmap/zync_launcher"\n        android:roundIcon="@mipmap/zync_launcher_round"',
            1,
        )
    manifest.write_text(text, encoding="utf-8")


def patch_gradle(android_dir: Path) -> None:
    for gradle in [
        android_dir / "app/build.gradle.kts",
        android_dir / "app/build.gradle",
    ]:
        if not gradle.exists():
            continue
        text = gradle.read_text(encoding="utf-8")
        text = text.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
        text = text.replace("targetSdk = flutter.targetSdkVersion", "targetSdk = 36")
        text = text.replace("compileSdk flutter.compileSdkVersion", "compileSdk 36")
        text = text.replace("targetSdk flutter.targetSdkVersion", "targetSdk 36")
        gradle.write_text(text, encoding="utf-8")


def vector_icon(include_background: bool) -> str:
    background = (
        f'<path android:fillColor="{CREAM}" android:pathData="M0,0H108V108H0Z" />'
        if include_background
        else ""
    )
    return f"""
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    {background}
    <path
        android:fillColor="@android:color/transparent"
        android:strokeColor="{ORANGE}"
        android:strokeWidth="8.2"
        android:strokeLineCap="round"
        android:pathData="M65.7,54A22,22 0,1 1,21.7,54A22,22 0,1 1,65.7,54" />
    <path
        android:fillColor="@android:color/transparent"
        android:strokeColor="{PLUM}"
        android:strokeWidth="8.2"
        android:strokeLineCap="round"
        android:pathData="M86.3,54A22,22 0,1 1,42.3,54A22,22 0,1 1,86.3,54" />
</vector>
"""


def monochrome_icon() -> str:
    return f"""
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="@android:color/transparent"
        android:strokeColor="{INK}"
        android:strokeWidth="8.2"
        android:strokeLineCap="round"
        android:pathData="M65.7,54A22,22 0,1 1,21.7,54A22,22 0,1 1,65.7,54M86.3,54A22,22 0,1 1,42.3,54A22,22 0,1 1,86.3,54" />
</vector>
"""


def apply_resources(main: Path) -> None:
    res = main / "res"

    write(
        res / "values/zync_colors.xml",
        f"""
<resources>
    <color name="zync_cream">{CREAM}</color>
    <color name="zync_orange">{ORANGE}</color>
    <color name="zync_plum">{PLUM}</color>
    <color name="zync_ink">{INK}</color>
</resources>
""",
    )

    write(res / "drawable/zync_launcher_foreground.xml", vector_icon(False))
    write(res / "drawable/zync_splash_mark.xml", vector_icon(False))
    write(res / "drawable/zync_launcher_legacy.xml", vector_icon(True))

    # API 24-25 fallback: a vector launcher resource. API 26+ gets an adaptive
    # icon of the same mark, so old devices never fall back to Flutter artwork.
    write(
        res / "mipmap-anydpi/zync_launcher.xml",
        vector_icon(True),
    )
    write(
        res / "mipmap-anydpi/zync_launcher_round.xml",
        vector_icon(True),
    )

    adaptive = """
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/zync_cream" />
    <foreground android:drawable="@drawable/zync_launcher_foreground" />
</adaptive-icon>
"""
    write(res / "mipmap-anydpi-v26/zync_launcher.xml", adaptive)
    write(res / "mipmap-anydpi-v26/zync_launcher_round.xml", adaptive)

    adaptive_monochrome = """
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/zync_cream" />
    <foreground android:drawable="@drawable/zync_launcher_foreground" />
    <monochrome android:drawable="@drawable/zync_launcher_monochrome" />
</adaptive-icon>
"""
    write(res / "drawable/zync_launcher_monochrome.xml", monochrome_icon())
    write(res / "mipmap-anydpi-v33/zync_launcher.xml", adaptive_monochrome)
    write(res / "mipmap-anydpi-v33/zync_launcher_round.xml", adaptive_monochrome)

    # Pre-Android-12 launch screen: warm cream background + centered Zync mark.
    launch_background = """
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/zync_cream" />
    <item
        android:width="108dp"
        android:height="108dp"
        android:gravity="center"
        android:drawable="@drawable/zync_splash_mark" />
</layer-list>
"""
    write(res / "drawable/launch_background.xml", launch_background)
    write(res / "drawable-v21/launch_background.xml", launch_background)

    # Android 12+ system splash. Keep it static/fast; the Flutter loading state
    # immediately continues the same visual language after the native splash.
    write(
        res / "values-v31/zync_launch_theme.xml",
        """
<resources>
    <style name="ZyncLaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/zync_cream</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/zync_splash_mark</item>
        <item name="android:windowSplashScreenAnimationDuration">220</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:statusBarColor">@color/zync_cream</item>
        <item name="android:navigationBarColor">@color/zync_cream</item>
    </style>
</resources>
""",
    )

    # Define the same named theme on all API levels, then point the manifest at
    # it. On API 31+, the version-qualified definition above is selected.
    write(
        res / "values/zync_launch_theme.xml",
        """
<resources>
    <style name="ZyncLaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowActionModeOverlay">true</item>
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:statusBarColor">@color/zync_cream</item>
        <item name="android:navigationBarColor">@color/zync_cream</item>
    </style>
</resources>
""",
    )


def patch_launch_theme(manifest: Path) -> None:
    text = manifest.read_text(encoding="utf-8")
    text = text.replace('android:theme="@style/LaunchTheme"', 'android:theme="@style/ZyncLaunchTheme"')
    manifest.write_text(text, encoding="utf-8")


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "build_app")
    android_dir = root / "android"
    main_dir = android_dir / "app/src/main"
    manifest = main_dir / "AndroidManifest.xml"
    if not manifest.exists():
        raise SystemExit(f"Android wrapper not found: {manifest}")

    patch_manifest(manifest)
    patch_gradle(android_dir)
    apply_resources(main_dir)
    patch_launch_theme(manifest)

    print("Applied Zync Android branding")
    print(f"manifest={manifest}")


if __name__ == "__main__":
    main()
