import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/apple_identity_provider.dart';
import '../core/cardverse_apple_auth.dart';
import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_google_auth.dart';
import '../core/cardverse_proof_sync.dart';
import '../core/cardverse_session_store.dart';
import '../core/google_identity_bridge.dart';
import '../ui/zync_design.dart';

class CardverseAccountScreen extends StatefulWidget {
  const CardverseAccountScreen({
    super.key,
    this.returnOnSignIn = false,
    this.sessionStore,
  });

  final bool returnOnSignIn;
  final CardverseSessionStore? sessionStore;

  @override
  State<CardverseAccountScreen> createState() =>
      _CardverseAccountScreenState();
}

class _CardverseAccountScreenState extends State<CardverseAccountScreen> {
  late final CardverseCloudClient _cloud;
  late final CardverseSessionStore _sessions;
  late final CardverseGoogleAuthService _auth;
  late final CardverseAppleAuthService _appleAuth;

  bool _loading = true;
  bool _busy = false;
  bool _signedIn = false;
  String _message = '';

  bool get _isZh =>
      Localizations.localeOf(context).toLanguageTag().startsWith('zh');

  bool get _googleLinkAvailable =>
      GoogleIdentityRuntime.nativeGoogleLinkAvailable;

  bool get _appleLinkAvailable => AppleIdentityRuntime.nativeIosAvailable;

  @override
  void initState() {
    super.initState();
    _cloud = CardverseCloudClient();
    _sessions = widget.sessionStore ?? CardverseSessionStore();
    final proofSync = CardverseProofSync(
      cloud: _cloud,
      sessions: _sessions,
    );
    _auth = CardverseGoogleAuthService(
      cloud: _cloud,
      sessions: _sessions,
      identity: const NativeGoogleIdentityProvider(),
      syncPendingProofs: proofSync.syncPending,
    );
    _appleAuth = CardverseAppleAuthService(
      cloud: _cloud,
      sessions: _sessions,
      identity: const NativeAppleIdentityProvider(),
      syncPendingProofs: proofSync.syncPending,
    );
    _load();
  }

  @override
  void dispose() {
    _cloud.close();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await _sessions.load();
    if (!mounted) return;
    setState(() {
      _signedIn = session != null;
      _loading = false;
    });
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });

    try {
      final result = await _auth.signIn();
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _message = result.auth.accountCreated
            ? (_isZh
                ? '你嘅 Zync World 已經開始保存到雲端。'
                : 'Your Zync World is now backed up to the cloud.')
            : (_isZh
                ? '已經搵返你原有嘅 Zync World。'
                : 'Your existing Zync World has been restored.');
      });

      if (widget.returnOnSignIn && mounted) {
        Navigator.of(context).pop(true);
      }
    } on GoogleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.code) {
          'google_sign_in_cancelled' => _isZh
              ? '你取消咗 Google 登入。'
              : 'Google sign-in was cancelled.',
          'google_sign_in_platform_unsupported' => _isZh
              ? '呢個版本暫時只支援 Android／iOS Google linking；Chrome／Web 未有 identity bridge。'
              : 'This build currently supports Google linking on Android and iOS; the Chrome/web identity bridge is not implemented.',
          'google_sign_in_native_bridge_missing' => _isZh
              ? 'Google identity bridge 未載入；請用已套用 Zync mobile wrapper 嘅 build。'
              : 'The Google identity bridge is missing from this build. Use a build generated with the Zync mobile wrapper.',
          'google_sign_in_configuration_invalid' => _isZh
              ? 'Google 登入設定無效；請檢查 Web Client ID。'
              : 'Google sign-in configuration is invalid. Check the Web client ID.',
          _ => _isZh
              ? '今次未能完成 Google 登入，請再試。'
              : 'Google sign-in could not be completed. Please try again.',
        };
      });
    } on CardverseGoogleAuthException {
      if (!mounted) return;
      setState(() {
        _message = _isZh
            ? '呢個版本暫時未設定好 Google 登入。'
            : 'Google sign-in is not configured for this build yet.';
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.failure) {
          CardverseCloudFailure.disabled => _isZh
              ? '雲端收藏功能喺呢個版本仲未開放。'
              : 'Cloud collection is not enabled in this build yet.',
          CardverseCloudFailure.unavailable => _isZh
              ? '暫時連接唔到 Zync 雲端，請稍後再試。'
              : 'Zync cloud is temporarily unavailable. Please try again.',
          _ => _isZh
              ? '登入未完成，請再試。'
              : 'Sign-in did not complete. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = _isZh
            ? '登入未完成，請稍後再試。'
            : 'Sign-in did not complete. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithApple() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });

    try {
      final result = await _appleAuth.signIn();
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _message = result.auth.accountCreated
            ? (_isZh
                ? '你的 Zync World 已連接到 Apple 帳戶並備份到雲端。'
                : 'Your Zync World is now connected through Apple and backed up to the cloud.')
            : (_isZh
                ? '已透過 Apple 恢復你原有的 Zync World。'
                : 'Your existing Zync World has been restored through Apple.');
      });

      if (widget.returnOnSignIn && mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.code) {
          'apple_sign_in_cancelled' => _isZh
              ? '已取消 Apple 登入。'
              : 'Apple sign-in was cancelled.',
          'apple_sign_in_platform_unsupported' => _isZh
              ? 'Apple 登入只會在 Zync iOS app 顯示。'
              : 'Apple sign-in is available only in the Zync iOS app.',
          'apple_sign_in_unavailable' => _isZh
              ? '這部裝置暫時未能使用「使用 Apple 登入」。'
              : 'Sign in with Apple is not available on this device.',
          'apple_sign_in_plugin_missing' => _isZh
              ? '這個 build 未載入 Apple identity plugin。'
              : 'The Apple identity plugin is missing from this build.',
          'apple_sign_in_token_invalid' => _isZh
              ? 'Apple 沒有回傳可驗證的身份 token，請再試一次。'
              : 'Apple did not return a valid identity token. Please try again.',
          _ => _isZh
              ? 'Apple 登入未能完成，請再試一次。'
              : 'Apple sign-in could not be completed. Please try again.',
        };
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.serverCode == 'cardverse_provider_audience_not_configured') {
          _message = _isZh
              ? 'Cardverse 伺服器尚未設定 Apple App ID。'
              : 'Cardverse is not configured with the Apple App ID yet.';
          return;
        }
        _message = switch (error.failure) {
          CardverseCloudFailure.disabled => _isZh
              ? '雲端收藏功能尚未在這個 build 啟用。'
              : 'Cloud collection is not enabled in this build yet.',
          CardverseCloudFailure.unavailable => _isZh
              ? '暫時連接不到 Zync 雲端，請稍後再試。'
              : 'Zync cloud is temporarily unavailable. Please try again.',
          _ => _isZh
              ? 'Apple 登入未能完成，請再試一次。'
              : 'Apple sign-in did not complete. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = _isZh
            ? 'Apple 登入未能完成，請稍後再試。'
            : 'Apple sign-in did not complete. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });

    final session = await _sessions.load();
    if (session != null) {
      try {
        await _cloud.logout(session.token);
      } catch (_) {
        // Explicit sign-out always removes the local bearer credential.
      }
    }
    await _sessions.clear();

    if (!mounted) return;
    setState(() {
      _signedIn = false;
      _busy = false;
      _message = _isZh
          ? '已經喺呢部裝置登出。你嘅雲端收藏唔會被刪除。'
          : 'Signed out on this device. Your cloud collection was not deleted.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectionBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _isZh ? 'Zync 帳戶' : 'Zync Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 14, 20, 36),
                        children: [
                          ZyncHeroPanel(
                            startColor: const Color(0xFFF2EEFF),
                            endColor: const Color(0xFFFFF3EB),
                            accentColor: ZyncPalette.plum,
                            child: Column(
                              children: [
                                ZyncIconTile(
                                  icon: _signedIn
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_outlined,
                                  size: 72,
                                  backgroundColor: Colors.white,
                                  foregroundColor: ZyncPalette.plum,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _signedIn
                                      ? (_isZh
                                          ? '你嘅 Zync World 已連接'
                                          : 'Your Zync World is connected')
                                      : (_isZh
                                          ? '保留你一路發現嘅世界'
                                          : 'Keep the world you discover'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _signedIn
                                      ? (_isZh
                                          ? '卡牌、卡包同獎勵會跟住你；換機之後都可以搵返。'
                                          : 'Your cards, packs and rewards can follow you and come back on another device.')
                                      : (_isZh
                                          ? '當你開始收藏卡牌，連接帳戶先會保存呢部分雲端進度。People history、私人對話同社交連結仍然留喺你部機。'
                                          : 'Connect an account to save your collection progress. People history, private conversations and social links stay on your device.'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: ZyncPalette.inkSoft,
                                        height: 1.4,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ZyncStatusPill(
                                      icon: _signedIn
                                          ? Icons.check_circle_rounded
                                          : Icons.lock_outline_rounded,
                                      label: _signedIn
                                          ? (_isZh
                                              ? '雲端收藏已連接'
                                              : 'Cloud collection connected')
                                          : (_isZh
                                              ? '私人資料 local-first'
                                              : 'Private data stays local-first'),
                                      foregroundColor: _signedIn
                                          ? const Color(0xFF176B57)
                                          : ZyncPalette.plum,
                                      backgroundColor: _signedIn
                                          ? const Color(0xFFDDF5EC)
                                          : Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_message.isNotEmpty) ...[
                            ZyncSurface(
                              shadow: false,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: ZyncPalette.plum,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_message)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (!_signedIn && !_googleLinkAvailable) ...[
                            ZyncSurface(
                              key: const ValueKey(
                                'zync-account-google-platform-note',
                              ),
                              shadow: false,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.devices_rounded,
                                    color: ZyncPalette.plum,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isZh
                                          ? 'Google 連結支援 Zync Android／iOS 原生 build；Chrome／Web 呢個 build 未實作 Google identity。'
                                          : 'Google linking is supported in native Zync Android/iOS builds. This build has no Chrome/web Google identity flow.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (!_signedIn) ...[
                            FilledButton.icon(
                              key: const ValueKey(
                                'zync-account-google-sign-in',
                              ),
                              onPressed:
                                  _busy || !_googleLinkAvailable ? null : _signIn,
                              icon: _busy
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                _isZh
                                    ? '使用 Google 繼續'
                                    : 'Continue with Google',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: ZyncPalette.ink,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if (_appleLinkAvailable) ...[
                              const SizedBox(height: 10),
                              SignInWithAppleButton(
                                key: const ValueKey(
                                  'zync-account-apple-sign-in',
                                ),
                                onPressed: _busy ? null : _signInWithApple,
                                text: _isZh
                                    ? '使用 Apple 繼續'
                                    : 'Continue with Apple',
                                height: 48,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(14),
                                ),
                              ),
                            ],
                          ] else
                            OutlinedButton.icon(
                              key: const ValueKey(
                                'zync-account-sign-out',
                              ),
                              onPressed: _busy ? null : _signOut,
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(
                                _isZh
                                    ? '喺呢部裝置登出'
                                    : 'Sign out on this device',
                              ),
                            ),
                          const SizedBox(height: 18),
                          Text(
                            _isZh
                                ? 'Google 只用嚟確認係你本人。Zync 唔會因為登入而將你嘅私人 People history 或對話搬上雲端。'
                                : 'Your sign-in provider is used only to confirm it is you. Signing in does not upload your private People history or conversations.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: ZyncPalette.inkSoft),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
