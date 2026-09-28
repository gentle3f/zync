import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/apple_identity_provider.dart';
import '../core/cardverse_apple_auth.dart';
import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_google_auth.dart';
import '../core/cardverse_identity_link.dart';
import '../core/cardverse_proof_sync.dart';
import '../core/cardverse_session_store.dart';
import '../core/google_identity_bridge.dart';
import '../ui/zync_design.dart';

class CardverseAccountLabScreen extends StatefulWidget {
  const CardverseAccountLabScreen({super.key});

  @override
  State<CardverseAccountLabScreen> createState() =>
      _CardverseAccountLabScreenState();
}

class _CardverseAccountLabScreenState
    extends State<CardverseAccountLabScreen> {
  late final CardverseCloudClient _cloud;
  late final CardverseSessionStore _sessions;
  late final CardverseGoogleAuthService _auth;
  late final CardverseAppleAuthService _appleAuth;
  late final CardverseIdentityLinkService _identityLinks;

  bool _busy = false;
  bool _signedIn = false;
  String _status = '';
  CardverseProofSyncResult? _lastProofSync;

  bool get _isZh =>
      Localizations.localeOf(context).toLanguageTag().startsWith('zh');

  bool get _apiConfigured =>
      const String.fromEnvironment('ZYNC_API_BASE').trim().isNotEmpty;

  bool get _googleClientConfigured => const String.fromEnvironment(
        'ZYNC_GOOGLE_SERVER_CLIENT_ID',
      )
          .trim()
          .endsWith('.apps.googleusercontent.com');

  String get _runtimeLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  @override
  void initState() {
    super.initState();
    _cloud = CardverseCloudClient();
    _sessions = CardverseSessionStore();
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
    _identityLinks = CardverseIdentityLinkService(
      cloud: _cloud,
      sessions: _sessions,
      googleIdentity: const NativeGoogleIdentityProvider(),
      appleIdentity: const NativeAppleIdentityProvider(),
    );
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await _sessions.load();
    if (!mounted) return;
    setState(() {
      _signedIn = session != null;
      _status = session == null
          ? ''
          : (_isZh ? '已找到有效雲端登入。' : 'Active cloud session found.');
    });
  }

  @override
  void dispose() {
    _cloud.close();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = _isZh ? '正在連接 Google…' : 'Connecting to Google…';
      _lastProofSync = null;
    });

    try {
      final result = await _auth.signIn();
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _lastProofSync = result.proofSync;
        _status = result.auth.accountCreated
            ? (_isZh
                ? 'Google 登入成功，Cardverse 雲端帳戶已建立。'
                : 'Google sign-in succeeded and a Cardverse cloud account was created.')
            : (_isZh
                ? 'Google 登入成功，已恢復原有 Cardverse 雲端帳戶。'
                : 'Google sign-in succeeded and the existing Cardverse cloud account was restored.');
      });
    } on CardverseGoogleAuthException catch (error) {
      if (!mounted) return;
      setState(() => _status = _messageForCode(error.code));
    } on GoogleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        final base = _messageForCode(error.code);
        final detail = error.detail.trim();
        _status = detail.isEmpty
            ? '$base [${error.code}]'
            : '$base [${error.code}; $detail]';
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() => _status = _messageForCloud(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _isZh
          ? '登入未完成。請稍後再試。'
          : 'Sign-in did not complete. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithApple() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = _isZh ? '正在連接 Apple…' : 'Connecting to Apple…';
      _lastProofSync = null;
    });

    try {
      final result = await _appleAuth.signIn();
      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _lastProofSync = result.proofSync;
        _status = result.auth.accountCreated
            ? (_isZh
                ? 'Apple 登入成功，Cardverse 雲端帳戶已建立。'
                : 'Apple sign-in succeeded and a Cardverse cloud account was created.')
            : (_isZh
                ? 'Apple 登入成功，已恢復原有 Cardverse 雲端帳戶。'
                : 'Apple sign-in succeeded and the existing Cardverse cloud account was restored.');
      });
    } on AppleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        final base = _messageForAppleCode(error.code);
        final detail = error.detail.trim();
        _status = detail.isEmpty
            ? '$base [${error.code}]'
            : '$base [${error.code}; $detail]';
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() => _status = _messageForCloud(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _isZh
          ? 'Apple 登入未完成。請稍後再試。'
          : 'Apple sign-in did not complete. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkGoogle() => _linkProvider(
        provider: 'google',
        action: _identityLinks.linkGoogle,
      );

  Future<void> _linkApple() => _linkProvider(
        provider: 'apple',
        action: _identityLinks.linkApple,
      );

  Future<void> _linkProvider({
    required String provider,
    required Future<CardverseProviderLinkResult> Function() action,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'link_start provider=${provider}';
    });

    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _status =
            'link_ok provider=${result.provider} restored=${result.restored}';
      });
    } on CardverseIdentityLinkException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.code == 'cardverse_link_session_missing') {
          _signedIn = false;
        }
        _status =
            'link_client_error provider=${provider} code=${error.code}';
      });
    } on GoogleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        final detail = error.detail.trim();
        _status = detail.isEmpty
            ? 'link_identity_error provider=google code=${error.code}'
            : 'link_identity_error provider=google code=${error.code} detail=${detail}';
      });
    } on AppleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        final detail = error.detail.trim();
        _status = detail.isEmpty
            ? 'link_identity_error provider=apple code=${error.code}'
            : 'link_identity_error provider=apple code=${error.code} detail=${detail}';
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.failure == CardverseCloudFailure.unauthorized) {
          _signedIn = false;
        }
        final status = error.statusCode?.toString() ?? 'none';
        final code = error.serverCode.isEmpty ? 'none' : error.serverCode;
        _status =
            'link_server_error provider=${provider} failure=${error.failure.name} status=${status} code=${code}';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = _isZh ? '正在登出…' : 'Signing out…';
    });

    try {
      final session = await _sessions.load();
      if (session != null) {
        try {
          await _cloud.logout(session.token);
        } catch (_) {
          // Always remove the local bearer credential on explicit logout.
        }
      }
      await _sessions.clear();
      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _lastProofSync = null;
        _status = _isZh ? '已在此裝置登出。' : 'Signed out on this device.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageForCloud(CardverseCloudException error) {
    if (error.serverCode == 'cardverse_provider_audience_not_configured') {
      return _isZh
          ? 'Cardverse server 未設定對應 identity provider audience。'
          : 'The Cardverse server has no audience configured for this identity provider.';
    }
    if (error.failure == CardverseCloudFailure.disabled) {
      return _isZh
          ? 'Cardverse staging API 仍然關閉。'
          : 'The Cardverse staging API is still disabled.';
    }
    if (error.failure == CardverseCloudFailure.unavailable) {
      return _isZh
          ? '暫時連接唔到 Cardverse staging。'
          : 'Cardverse staging is temporarily unavailable.';
    }
    if (error.failure == CardverseCloudFailure.unauthorized) {
      return _isZh
          ? 'Identity provider／Cardverse 驗證被拒絕。'
          : 'Identity-provider/Cardverse authentication was rejected.';
    }
    return _isZh
        ? 'Cardverse staging 拒絕咗今次登入要求。'
        : 'Cardverse staging rejected this sign-in request.';
  }

  String _messageForAppleCode(String code) {
    switch (code) {
      case 'apple_sign_in_cancelled':
        return _isZh ? '已取消 Apple 登入。' : 'Apple sign-in was cancelled.';
      case 'apple_sign_in_platform_unsupported':
        return _isZh
            ? 'Apple 登入只會在 Zync iOS app 啟用。'
            : 'Apple sign-in is enabled only in the Zync iOS app.';
      case 'apple_sign_in_unavailable':
        return _isZh
            ? '這部裝置暫時未能使用「使用 Apple 登入」。'
            : 'Sign in with Apple is unavailable on this device.';
      case 'apple_sign_in_plugin_missing':
        return _isZh
            ? 'Apple identity plugin 未載入。'
            : 'The Apple identity plugin is missing.';
      case 'apple_sign_in_token_invalid':
        return _isZh
            ? 'Apple 沒有回傳可驗證的 identity token。'
            : 'Apple did not return a valid identity token.';
      default:
        return _isZh
            ? 'Apple 登入失敗。請檢查 iOS capability／Apple App ID 設定。'
            : 'Apple sign-in failed. Check the iOS capability and Apple App ID configuration.';
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'google_server_client_id_not_configured':
      case 'google_sign_in_configuration_invalid':
        return _isZh
            ? 'QA build 未設定 Google Web Client ID。'
            : 'This QA build has no Google Web Client ID configured.';
      case 'google_sign_in_cancelled':
        return _isZh ? '已取消 Google 登入。' : 'Google sign-in was cancelled.';
      case 'google_sign_in_in_flight':
        return _isZh
            ? 'Google 登入視窗已經開緊。'
            : 'A Google sign-in request is already active.';
      case 'google_sign_in_platform_unsupported':
        return _isZh
            ? '呢個 build 嘅 Google identity bridge 支援 Android／iOS；Chrome／Web 未實作。'
            : 'This build supports the Google identity bridge on Android and iOS; Chrome/web is not implemented.';
      case 'google_sign_in_native_bridge_missing':
        return _isZh
            ? 'Google identity bridge 未載入；請確認 build 經 Zync mobile wrapper 生成。'
            : 'The Google identity bridge is missing; build with the Zync mobile wrapper.';
      default:
        return _isZh
            ? 'Google 登入失敗。請確認目前平台 OAuth 設定。'
            : 'Google sign-in failed. Check the OAuth configuration for this platform.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofSync = _lastProofSync;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isZh ? 'Cardverse 帳戶實驗室' : 'Cardverse Account Lab'),
      ),
      body: ConnectionBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ZyncSurface(
                borderColor: const Color(0xFFE0D9FF),
                backgroundColor: const Color(0xFFF7F5FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh
                          ? '只供 QA：Google／Apple → 一次性 nonce → Cardverse session'
                          : 'QA only: Google/Apple → one-time nonce → Cardverse session',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isZh
                          ? 'Google／Apple ID token 只會交俾 staging server 驗證；畫面、log 同本機一般儲存都唔會顯示 token。'
                          : 'Google/Apple ID tokens are sent only to the staging server for verification; they are never shown in this UI or ordinary local storage/logging.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ZyncSurface(
                key: const ValueKey('cardverse-google-diagnostic-state'),
                shadow: false,
                borderColor: const Color(0xFFE0D9FF),
                backgroundColor: const Color(0xFFF9F8FC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Runtime diagnostics',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('runtime=$_runtimeLabel'),
                    Text('api_base_configured=$_apiConfigured'),
                    Text('google_web_client_configured=$_googleClientConfigured'),
                    Text(
                      'native_android_bridge_available='
                      '${GoogleIdentityRuntime.nativeAndroidBridgeAvailable}',
                    ),
                    Text(
                      'native_ios_bridge_available='
                      '${GoogleIdentityRuntime.nativeIosBridgeAvailable}',
                    ),
                    Text(
                      'google_ios_client_configured='
                      '${GoogleIdentityRuntime.iosClientConfigured}',
                    ),
                    Text(
                      'apple_native_ios_available='
                      '${AppleIdentityRuntime.nativeIosAvailable}',
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Chrome can exercise UI, but Google linking is not '
                        'implemented on web in this build. Use a native Android '
                        'or iOS wrapper for identity smoke testing.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: ZyncPalette.inkSoft),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _signedIn
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                title: Text(
                  _signedIn
                      ? (_isZh ? '已登入 Cardverse' : 'Signed in to Cardverse')
                      : (_isZh ? '未登入 Cardverse' : 'Not signed in'),
                ),
                subtitle: _status.isEmpty ? null : Text(_status),
              ),
              if (proofSync != null) ...[
                const SizedBox(height: 8),
                Text(
                  _isZh
                      ? 'Proof sync：已兌換 ${proofSync.redeemed}；已丟棄 ${proofSync.discarded}；待處理 ${proofSync.remaining}'
                      : 'Proof sync: ${proofSync.redeemed} redeemed, ${proofSync.discarded} discarded, ${proofSync.remaining} pending',
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const ValueKey('cardverse-google-sign-in'),
                onPressed: _busy ||
                        _signedIn ||
                        !GoogleIdentityRuntime.nativeGoogleLinkAvailable
                    ? null
                    : _signIn,
                icon: _busy && !_signedIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(
                  _isZh ? '使用 Google 登入' : 'Sign in with Google',
                ),
              ),
              if (AppleIdentityRuntime.nativeIosAvailable) ...[
                const SizedBox(height: 10),
                SignInWithAppleButton(
                  key: const ValueKey('cardverse-apple-sign-in'),
                  onPressed: _busy || _signedIn ? null : _signInWithApple,
                  text: _isZh ? '使用 Apple 登入' : 'Sign in with Apple',
                  height: 48,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(14),
                  ),
                ),
              ],
              if (_signedIn) ...[
                const SizedBox(height: 18),
                Text(
                  'Provider-link diagnostics',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('cardverse-link-google'),
                  onPressed: _busy ||
                          !GoogleIdentityRuntime.nativeGoogleLinkAvailable
                      ? null
                      : _linkGoogle,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(
                    _isZh ? '驗證並連接 Google' : 'Verify & link Google',
                  ),
                ),
                if (AppleIdentityRuntime.nativeIosAvailable) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const ValueKey('cardverse-link-apple'),
                    onPressed: _busy ? null : _linkApple,
                    icon: const Icon(Icons.link_rounded),
                    label: Text(
                      _isZh ? '驗證並連接 Apple' : 'Verify & link Apple',
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('cardverse-sign-out'),
                onPressed: _busy || !_signedIn ? null : _logout,
                icon: const Icon(Icons.logout_rounded),
                label: Text(_isZh ? '登出' : 'Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
