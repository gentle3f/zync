import 'package:flutter/material.dart';

import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_google_auth.dart';
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

  bool _busy = false;
  bool _signedIn = false;
  String _status = '';
  CardverseProofSyncResult? _lastProofSync;

  bool get _isZh =>
      Localizations.localeOf(context).toLanguageTag().startsWith('zh');

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
          ? 'Google／Cardverse 驗證被拒絕。'
          : 'Google/Cardverse authentication was rejected.';
    }
    return _isZh
        ? 'Cardverse staging 拒絕咗今次登入要求。'
        : 'Cardverse staging rejected this sign-in request.';
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
      default:
        return _isZh
            ? 'Google 登入失敗。請確認 Android OAuth 設定。'
            : 'Google sign-in failed. Check the Android OAuth configuration.';
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
                          ? '只供 QA：Google → 一次性 nonce → Cardverse session'
                          : 'QA only: Google → one-time nonce → Cardverse session',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isZh
                          ? 'ID token 只會交俾 staging server 驗證；畫面、log 同本機一般儲存都唔會顯示 token。'
                          : 'The ID token is sent only to the staging server for verification; it is never shown in this UI or ordinary local storage/logging.',
                    ),
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
                onPressed: _busy || _signedIn ? null : _signIn,
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
