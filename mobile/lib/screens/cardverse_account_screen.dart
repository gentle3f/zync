import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/apple_identity_provider.dart';
import '../core/cardverse_account_deletion.dart';
import '../core/cardverse_apple_auth.dart';
import '../core/cardverse_cloud_client.dart';
import '../core/cardverse_google_auth.dart';
import '../core/cardverse_identity_link.dart';
import '../core/cardverse_proof_sync.dart';
import '../core/cardverse_session_store.dart';
import '../core/google_identity_bridge.dart';
import '../ui/zync_design.dart';

class CardverseAccountScreen extends StatefulWidget {
  const CardverseAccountScreen({
    super.key,
    this.returnOnSignIn = false,
    this.sessionStore,
    this.accountDeletionController,
  });

  final bool returnOnSignIn;
  final CardverseSessionStore? sessionStore;
  final CardverseAccountDeletionController? accountDeletionController;

  @override
  State<CardverseAccountScreen> createState() =>
      _CardverseAccountScreenState();
}

class _CardverseAccountScreenState extends State<CardverseAccountScreen> {
  late final CardverseCloudClient _cloud;
  late final CardverseSessionStore _sessions;
  late final CardverseGoogleAuthService _auth;
  late final CardverseAppleAuthService _appleAuth;
  late final CardverseIdentityLinkService _identityLinks;
  late final CardverseAccountDeletionController _accountDeletion;

  bool _loading = true;
  bool _busy = false;
  bool _signedIn = false;
  String _message = '';
  String? _linkingProvider;
  final Set<String> _linkedThisVisit = <String>{};

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
    _identityLinks = CardverseIdentityLinkService(
      cloud: _cloud,
      sessions: _sessions,
      googleIdentity: const NativeGoogleIdentityProvider(),
      appleIdentity: const NativeAppleIdentityProvider(),
    );
    _accountDeletion = widget.accountDeletionController ??
        CardverseAccountDeletionService(
          cloud: _cloud,
          sessions: _sessions,
          googleIdentity: const NativeGoogleIdentityProvider(),
          appleIdentity: const NativeAppleIdentityProvider(),
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

  String _providerName(String provider) =>
      provider == 'apple' ? 'Apple' : 'Google';

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
      _linkingProvider = provider;
      _message = '';
    });

    final providerName = _providerName(provider);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _linkedThisVisit.add(provider);
        _message = result.restored
            ? (_isZh
                ? '已重新連接 $providerName。之後可以用這個方式返回同一個 Zync World。'
                : '$providerName was re-linked. You can use it to return to this same Zync World.')
            : (_isZh
                ? '已確認並連接 $providerName。之後可以用這個方式返回同一個 Zync World。'
                : '$providerName is now verified and linked to this Zync World.');
      });
    } on CardverseIdentityLinkException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.code == 'cardverse_link_session_missing') {
          _signedIn = false;
          _message = _isZh
              ? '登入狀態已失效。請先重新登入，再連接另一個登入方式。'
              : 'Your session has expired. Sign in again before adding another sign-in method.';
        } else if (error.code == 'google_server_client_id_not_configured') {
          _message = _isZh
              ? '這個 build 尚未設定 Google 登入。'
              : 'Google sign-in is not configured for this build.';
        } else {
          _message = _isZh
              ? '未能連接 $providerName，請再試一次。'
              : 'Could not link $providerName. Please try again.';
        }
      });
    } on GoogleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.code) {
          'google_sign_in_cancelled' => _isZh
              ? '已取消 Google 驗證，帳戶沒有任何改動。'
              : 'Google verification was cancelled. Nothing was changed.',
          'google_sign_in_configuration_invalid' => _isZh
              ? 'Google 登入設定未完成，帳戶沒有任何改動。'
              : 'Google sign-in is not configured correctly. Nothing was changed.',
          _ => _isZh
              ? 'Google 驗證未能完成，帳戶沒有任何改動。'
              : 'Google verification could not be completed. Nothing was changed.',
        };
      });
    } on AppleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.code) {
          'apple_sign_in_cancelled' => _isZh
              ? '已取消 Apple 驗證，帳戶沒有任何改動。'
              : 'Apple verification was cancelled. Nothing was changed.',
          'apple_sign_in_unavailable' ||
          'apple_sign_in_platform_unsupported' => _isZh
              ? '這部裝置暫時未能使用 Apple 驗證，帳戶沒有任何改動。'
              : 'Apple verification is unavailable on this device. Nothing was changed.',
          _ => _isZh
              ? 'Apple 驗證未能完成，帳戶沒有任何改動。'
              : 'Apple verification could not be completed. Nothing was changed.',
        };
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.failure == CardverseCloudFailure.unauthorized) {
          _signedIn = false;
          _message = _isZh
              ? '登入狀態已失效。請重新登入；沒有連接任何新帳戶。'
              : 'Your session has expired. Sign in again; no new identity was linked.';
        } else if (error.serverCode == 'cardverse_identity_already_linked') {
          _message = _isZh
              ? '這個 $providerName 身份已屬於另一個 Zync World。系統沒有合併或改動任何帳戶。你可以登出後用該身份進入原有 Zync World，或者改用另一個身份。'
              : 'This $providerName identity already belongs to another Zync World. Nothing was merged or changed. Sign out and use that identity to open its existing world, or use another identity.';
        } else if (error.serverCode == 'cardverse_provider_already_linked') {
          _message = _isZh
              ? '這個 Zync World 已經連接了另一個 $providerName 身份。系統沒有覆蓋原有連接。'
              : 'This Zync World already has a different $providerName identity linked. The existing link was not replaced.';
        } else if (error.serverCode ==
            'cardverse_provider_audience_not_configured') {
          _message = _isZh
              ? '$providerName 尚未在 Zync 伺服器完成設定，帳戶沒有任何改動。'
              : '$providerName is not fully configured on Zync yet. Nothing was changed.';
        } else {
          _message = _isZh
              ? '暫時未能連接 $providerName，帳戶沒有任何改動。'
              : 'Could not link $providerName right now. Nothing was changed.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _linkingProvider = null;
        });
      }
    }
  }

  Future<bool> _confirmAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _isZh ? '刪除 Zync 帳戶？' : 'Delete Zync account?',
        ),
        content: Text(
          _isZh
              ? '呢個操作會永久解除 Google／Apple 登入同你雲端 Zync World 嘅連結，並令呢個雲端帳戶無法再使用。你部機入面 local-first 嘅 People history 同私人對話係另一層資料，唔會因為刪除雲端帳戶而自動清除。'
              : 'This permanently disconnects Google/Apple sign-ins from your cloud Zync World and makes that cloud account unusable. Your local-first People history and private conversations are separate device data and are not automatically erased by deleting the cloud account.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('zync-account-delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            key: const ValueKey('zync-account-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            child: Text(_isZh ? '繼續刪除' : 'Continue'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<String?> _chooseDeletionProvider() async {
    final googleAvailable = _googleLinkAvailable;
    final appleAvailable = _appleLinkAvailable;
    if (!googleAvailable && !appleAvailable) return null;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _isZh ? '驗證身份先刪除' : 'Verify before deleting',
        ),
        content: Text(
          _isZh
              ? '為咗防止其他人誤刪帳戶，你要用已連接嘅登入方式重新驗證。若呢個 Zync World 連接咗 Apple，伺服器可能會要求你一定要用 Apple 完成最後驗證同撤銷授權。'
              : 'To prevent accidental or unauthorized deletion, verify again with a linked sign-in method. If this Zync World has Apple linked, the server may require Apple for the final verification and authorization revocation.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('zync-account-delete-provider-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          if (googleAvailable)
            TextButton(
              key: const ValueKey('zync-account-delete-google'),
              onPressed: () => Navigator.of(dialogContext).pop('google'),
              child: Text(_isZh ? '用 Google 驗證' : 'Verify with Google'),
            ),
          if (appleAvailable)
            TextButton(
              key: const ValueKey('zync-account-delete-apple'),
              onPressed: () => Navigator.of(dialogContext).pop('apple'),
              child: Text(_isZh ? '用 Apple 驗證' : 'Verify with Apple'),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    final confirmed = await _confirmAccountDeletion();
    if (!mounted || !confirmed) return;

    final provider = await _chooseDeletionProvider();
    if (!mounted) return;
    if (provider == null) {
      setState(() {
        _message = _isZh
            ? '呢個裝置而家冇可用嘅登入驗證方式，所以未有刪除任何資料。'
            : 'No supported identity verification method is available on this device. Nothing was deleted.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = '';
    });

    try {
      if (provider == 'apple') {
        await _accountDeletion.deleteWithApple();
      } else {
        await _accountDeletion.deleteWithGoogle();
      }

      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _linkedThisVisit.clear();
        _message = _isZh
            ? 'Zync 雲端帳戶已刪除，登入連結同雲端 session 已解除。People history 同私人對話仍然只留喺你呢部裝置。'
            : 'Your Zync cloud account was deleted and its sign-in links and cloud sessions were removed. Your local People history and private conversations remain on this device.';
      });
    } on CardverseAccountDeletionException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.code == 'cardverse_delete_session_missing') {
          _signedIn = false;
          _message = _isZh
              ? '登入狀態已失效。請重新登入先可以刪除帳戶。'
              : 'Your session has expired. Sign in again before deleting the account.';
        } else if (error.code == 'google_server_client_id_not_configured') {
          _message = _isZh
              ? '呢個 build 未完成 Google 驗證設定，帳戶冇被刪除。'
              : 'Google verification is not configured for this build. The account was not deleted.';
        } else {
          _message = _isZh
              ? '暫時未能開始刪除帳戶，冇任何資料被改動。'
              : 'Account deletion could not start. Nothing was changed.';
        }
      });
    } on GoogleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.code == 'google_sign_in_cancelled'
            ? (_isZh
                ? '你取消咗 Google 驗證，帳戶冇被刪除。'
                : 'Google verification was cancelled. The account was not deleted.')
            : (_isZh
                ? 'Google 驗證未完成，帳戶冇被刪除。'
                : 'Google verification did not complete. The account was not deleted.');
      });
    } on AppleIdentityException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.code == 'apple_sign_in_cancelled'
            ? (_isZh
                ? '你取消咗 Apple 驗證，帳戶冇被刪除。'
                : 'Apple verification was cancelled. The account was not deleted.')
            : (_isZh
                ? 'Apple 驗證未完成，帳戶冇被刪除。'
                : 'Apple verification did not complete. The account was not deleted.');
      });
    } on CardverseCloudException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.failure == CardverseCloudFailure.unauthorized) {
          _signedIn = false;
          _message = _isZh
              ? '登入狀態已失效。請重新登入先再刪除帳戶。'
              : 'Your session has expired. Sign in again before deleting the account.';
        } else if (error.serverCode == 'cardverse_apple_reauth_required') {
          _message = _isZh
              ? '呢個 Zync World 連接咗 Apple。請重新揀「刪除帳戶」，並用 Apple 完成最後驗證；今次冇刪除任何資料。'
              : 'This Zync World has Apple linked. Start deletion again and verify with Apple to finish; nothing was deleted this time.';
        } else if (error.serverCode == 'cardverse_apple_revoke_failed' ||
            error.serverCode == 'cardverse_apple_token_exchange_failed' ||
            error.serverCode == 'cardverse_apple_revocation_not_configured') {
          _message = _isZh
              ? '暫時未能安全撤銷 Apple 授權，所以帳戶冇被刪除。請稍後再試。'
              : 'Apple authorization could not be safely revoked, so the account was not deleted. Please try again later.';
        } else {
          _message = _isZh
              ? '帳戶刪除未完成，冇任何資料被改動。請稍後再試。'
              : 'Account deletion did not complete. Nothing was changed. Please try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = _isZh
            ? '帳戶刪除未完成，冇任何資料被改動。'
            : 'Account deletion did not complete. Nothing was changed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
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
      _linkedThisVisit.clear();
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
                          ] else ...[
                            if (_appleLinkAvailable) ...[
                              ZyncSurface(
                                key: const ValueKey(
                                  'zync-account-provider-recovery',
                                ),
                                shadow: false,
                                borderColor: const Color(0xFFE0D9FF),
                                backgroundColor: const Color(0xFFF9F8FF),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const ZyncIconTile(
                                          icon: Icons.key_rounded,
                                          size: 42,
                                          backgroundColor: Colors.white,
                                          foregroundColor: ZyncPalette.plum,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _isZh
                                                    ? '讓同一個 Zync World 跟你去不同裝置'
                                                    : 'Keep one Zync World across devices',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _isZh
                                                    ? '再驗證一個登入方式，會把它連接到你目前已登入的 Zync World。系統不會自動合併另一個 Zync World，也不會上傳你的 People history 或私人對話。'
                                                    : 'Verify another sign-in method and attach it to the Zync World you are already using. Zync will not automatically merge a different Zync World or upload your People history or private conversations.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          ZyncPalette.inkSoft,
                                                      height: 1.4,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_linkedThisVisit.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final provider
                                              in _linkedThisVisit)
                                            ZyncStatusPill(
                                              icon: Icons.verified_rounded,
                                              label: _isZh
                                                  ? '${_providerName(provider)} 已在今次確認連接'
                                                  : '${_providerName(provider)} linked this visit',
                                              foregroundColor:
                                                  const Color(0xFF176B57),
                                              backgroundColor:
                                                  const Color(0xFFDDF5EC),
                                            ),
                                        ],
                                      ),
                                    ],
                                    if (_linkingProvider != null) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isZh
                                                ? '正在驗證 ${_providerName(_linkingProvider!)}…'
                                                : 'Verifying ${_providerName(_linkingProvider!)}…',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    if (_googleLinkAvailable)
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          key: const ValueKey(
                                            'zync-account-link-google',
                                          ),
                                          onPressed:
                                              _busy ? null : _linkGoogle,
                                          icon: const Icon(
                                            Icons.link_rounded,
                                          ),
                                          label: Text(
                                            _isZh
                                                ? '使用 Google 驗證並連接'
                                                : 'Verify & link Google',
                                          ),
                                        ),
                                      ),
                                    if (_googleLinkAvailable)
                                      const SizedBox(height: 10),
                                    SignInWithAppleButton(
                                      key: const ValueKey(
                                        'zync-account-link-apple',
                                      ),
                                      onPressed: _busy ? null : _linkApple,
                                      text: _isZh
                                          ? '使用 Apple 繼續'
                                          : 'Continue with Apple',
                                      height: 48,
                                      borderRadius:
                                          const BorderRadius.all(
                                        Radius.circular(14),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _isZh
                                          ? '如果這個 Google／Apple 身份已屬於另一個 Zync World，連接會停止；兩邊資料都不會被合併或覆蓋。'
                                          : 'If that Google or Apple identity already belongs to another Zync World, linking stops. Neither world is merged or overwritten.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ZyncPalette.inkSoft,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
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
                            const SizedBox(height: 10),
                            TextButton.icon(
                              key: const ValueKey(
                                'zync-account-delete-account',
                              ),
                              onPressed: _busy ? null : _deleteAccount,
                              icon: const Icon(Icons.delete_forever_rounded),
                              label: Text(
                                _isZh
                                    ? '永久刪除 Zync 帳戶'
                                    : 'Permanently delete Zync account',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFB3261E),
                              ),
                            ),
                          ],
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