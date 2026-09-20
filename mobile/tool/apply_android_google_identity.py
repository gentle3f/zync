#!/usr/bin/env python3
"""Inject Zync's Android Credential Manager Google identity bridge.

The bridge accepts the server-issued Cardverse nonce for every authentication
attempt. This keeps the Android token request bound to the one-time server
challenge instead of reusing a process-wide nonce.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


KTS_DEPENDENCIES = """
dependencies {
    implementation("androidx.credentials:credentials:1.6.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.6.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.2.1")
}
"""

GROOVY_DEPENDENCIES = """
dependencies {
    implementation 'androidx.credentials:credentials:1.6.0'
    implementation 'androidx.credentials:credentials-play-services-auth:1.6.0'
    implementation 'com.google.android.libraries.identity.googleid:googleid:1.2.1'
}
"""

MARKER = "com.google.android.libraries.identity.googleid:googleid"


def patch_gradle_text(text: str, flavor: str) -> str:
    if MARKER in text:
        return text
    block = KTS_DEPENDENCIES if flavor == "kts" else GROOVY_DEPENDENCIES
    return text.rstrip() + "\n\n" + block.strip() + "\n"


def main_activity_source(package_name: str) -> str:
    template = """package __PACKAGE__

import android.content.MutableContextWrapper
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "zync/google_identity"
        private const val AUTHENTICATE = "authenticateGoogle"
    }

    private val credentialManager by lazy { CredentialManager.create(this) }
    private var googleAuthInFlight = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                AUTHENTICATE -> authenticateGoogle(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun authenticateGoogle(call: MethodCall, result: MethodChannel.Result) {
        if (googleAuthInFlight) {
            result.error(
                "google_sign_in_in_flight",
                "A Google sign-in request is already active.",
                null,
            )
            return
        }

        val serverClientId = call.argument<String>("serverClientId")?.trim().orEmpty()
        val nonce = call.argument<String>("nonce")?.trim().orEmpty()
        if (
            serverClientId.isEmpty() ||
            !serverClientId.endsWith(".apps.googleusercontent.com") ||
            nonce.isEmpty() ||
            nonce.length > 512
        ) {
            result.error(
                "google_sign_in_configuration_invalid",
                "Google sign-in configuration is invalid.",
                null,
            )
            return
        }

        val option = GetSignInWithGoogleOption.Builder(serverClientId)
            .setNonce(nonce)
            .build()
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(option)
            .build()

        googleAuthInFlight = true
        val activityContext = MutableContextWrapper(this)
        credentialManager.getCredentialAsync(
            activityContext,
            request,
            null,
            mainExecutor,
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(response: GetCredentialResponse) {
                    googleAuthInFlight = false
                    val credential = response.credential
                    if (credential !is CustomCredential) {
                        result.error(
                            "google_sign_in_unexpected_credential",
                            "Google sign-in returned an unexpected credential.",
                            mapOf(
                                "credentialClass" to credential::class.java.simpleName,
                            ),
                        )
                        return
                    }

                    val subtype = credential.data.getString(
                        GoogleIdTokenCredential.BUNDLE_KEY_GOOGLE_ID_TOKEN_SUBTYPE,
                    )
                    val knownType =
                        credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL ||
                        credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_SIWG_CREDENTIAL
                    if (!knownType) {
                        result.error(
                            "google_sign_in_unexpected_credential",
                            "Google sign-in returned an unexpected credential.",
                            mapOf(
                                "credentialType" to credential.type,
                                "credentialSubtype" to subtype,
                            ),
                        )
                        return
                    }

                    try {
                        val googleCredential =
                            GoogleIdTokenCredential.createFrom(credential.data)
                        result.success(googleCredential.idToken)
                    } catch (error: GoogleIdTokenParsingException) {
                        result.error(
                            "google_sign_in_token_invalid",
                            "Google sign-in returned an invalid ID token.",
                            mapOf(
                                "credentialType" to credential.type,
                                "credentialSubtype" to subtype,
                                "exceptionClass" to error::class.java.simpleName,
                            ),
                        )
                    } catch (error: Exception) {
                        result.error(
                            "google_sign_in_token_parse_failed",
                            "Google sign-in token parsing failed.",
                            mapOf(
                                "credentialType" to credential.type,
                                "credentialSubtype" to subtype,
                                "exceptionClass" to error::class.java.simpleName,
                            ),
                        )
                    }
                }

                override fun onError(error: GetCredentialException) {
                    googleAuthInFlight = false
                    val safeDetail = mapOf(
                        "exceptionType" to error.type,
                        "exceptionClass" to error::class.java.simpleName,
                        "causeClass" to (error.cause?.javaClass?.simpleName ?: ""),
                    )
                    if (error is GetCredentialCancellationException) {
                        result.error(
                            "google_sign_in_cancelled",
                            "Google sign-in was cancelled.",
                            safeDetail,
                        )
                    } else {
                        result.error(
                            "google_sign_in_failed",
                            "Google sign-in failed.",
                            safeDetail,
                        )
                    }
                }
            },
        )
    }
}
"""
    return template.replace("__PACKAGE__", package_name)


def find_gradle(android_dir: Path) -> tuple[Path, str]:
    kts = android_dir / "app/build.gradle.kts"
    groovy = android_dir / "app/build.gradle"
    if kts.exists():
        return kts, "kts"
    if groovy.exists():
        return groovy, "groovy"
    raise SystemExit("Android app Gradle file not found")


def find_main_activity(root: Path) -> Path:
    matches = list((root / "android/app/src/main").rglob("MainActivity.kt"))
    if len(matches) != 1:
        raise SystemExit(f"Expected exactly one MainActivity.kt, found {len(matches)}")
    return matches[0]


def package_from_activity(text: str) -> str:
    match = re.search(r"^package\s+([A-Za-z0-9_.]+)\s*$", text, re.MULTILINE)
    if not match:
        raise SystemExit("Could not determine MainActivity package")
    return match.group(1)


def check_template(root: Path) -> None:
    gradle, flavor = find_gradle(root / "android")
    original = gradle.read_text(encoding="utf-8")
    patched = patch_gradle_text(original, flavor)
    if MARKER not in patched:
        raise SystemExit("Google Identity dependency patch failed")
    activity = find_main_activity(root)
    package_name = package_from_activity(activity.read_text(encoding="utf-8"))
    source = main_activity_source(package_name)
    if 'setNonce(nonce)' not in source or CHANNEL_LITERAL not in source:
        raise SystemExit("Google identity bridge template invalid")
    print(f"Zync Google identity bridge matches generated template: {activity}")


CHANNEL_LITERAL = 'zync/google_identity'


def configure(root: Path) -> None:
    android_dir = root / "android"
    gradle, flavor = find_gradle(android_dir)
    original = gradle.read_text(encoding="utf-8")
    gradle.write_text(patch_gradle_text(original, flavor), encoding="utf-8")

    activity = find_main_activity(root)
    package_name = package_from_activity(activity.read_text(encoding="utf-8"))
    activity.write_text(main_activity_source(package_name), encoding="utf-8")

    print("Configured Zync Android Google identity bridge")
    print(f"gradle={gradle}")
    print(f"activity={activity}")


def self_test() -> None:
    kts = 'plugins { id("com.android.application") }\nandroid {}\n'
    groovy = "plugins { id 'com.android.application' }\nandroid {}\n"
    assert MARKER in patch_gradle_text(kts, "kts")
    assert MARKER in patch_gradle_text(groovy, "groovy")
    assert patch_gradle_text(patch_gradle_text(kts, "kts"), "kts").count(MARKER) == 1

    source = main_activity_source("com.gmail.gentle3f.myproject")
    assert source.startswith("package com.gmail.gentle3f.myproject")
    assert 'GetSignInWithGoogleOption.Builder(serverClientId)' in source
    assert '.setNonce(nonce)' in source
    assert 'MutableContextWrapper(this)' in source
    assert '"causeClass" to' in source
    assert 'GoogleIdTokenCredential.createFrom' in source
    assert CHANNEL_LITERAL in source
    assert 'Log.' not in source
    print("Zync Android Google identity bridge self-test passed")


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
