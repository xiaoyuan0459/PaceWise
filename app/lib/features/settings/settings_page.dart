import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/analytics.dart';
import 'package:pacebridge/data/auth.dart';
import 'package:pacebridge/data/core.dart';
import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/data/prefs.dart';
import 'package:pacebridge/data/sync.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appInfo = ref.watch(appInfoProvider);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(l10n.navSettings)),
        SliverList(
          delegate: SliverChildListDelegate([
            const _AccountTile(),
            const _SyncTile(),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.settingsDataDir),
              subtitle: Text(
                appInfo.dataDir.isEmpty
                    ? l10n.settingsAppData
                    : appInfo.dataDir,
              ),
            ),
            const _PrivacyTile(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              subtitle: Text(
                '${l10n.version} 3.2.1 · schema ${appInfo.schemaVersion}',
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final outcome = await showDialog<AuthOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AuthDialog(),
    );
    if (!context.mounted || outcome == null) return;
    if (outcome == AuthOutcome.success) {
      ref.invalidate(authStatusProvider);
      invalidateAnalytics(ref);
      _toast(context, l10n.authSuccess);
    } else if (outcome == AuthOutcome.denied) {
      _toast(context, l10n.authDenied);
    } else if (outcome == AuthOutcome.expired) {
      _toast(context, l10n.authExpired);
    } else if (outcome == AuthOutcome.failed) {
      _toast(context, l10n.authFailed);
    }
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountDisconnectTitle),
        content: Text(l10n.accountDisconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      rust.authDisconnect();
    } catch (_) {}
    ref.invalidate(authStatusProvider);
    if (!context.mounted) return;
    _toast(context, l10n.accountDisconnected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(authStatusProvider).asData?.value;
    final connected = status?.authorized ?? false;
    final needsReauth = status?.needsReauth ?? false;
    final nickname = status?.nickname;
    final name = nickname != null && nickname.trim().isNotEmpty
        ? nickname
        : status?.userId;
    final subtitle = connected
        ? (name == null ? l10n.authSuccess : l10n.accountConnectedAs(name))
        : needsReauth
        ? l10n.accountNeedsReauth
        : l10n.settingsNotConnected;

    return ListTile(
      leading: Icon(
        connected ? Icons.account_circle : Icons.account_circle_outlined,
      ),
      title: Text(l10n.settingsAccount),
      subtitle: Text(subtitle),
      trailing: connected
          ? Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            )
          : needsReauth
          ? Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            )
          : const Icon(Icons.chevron_right),
      onTap: () =>
          connected ? _confirmDisconnect(context, ref) : _connect(context, ref),
    );
  }
}

class _SyncTile extends ConsumerStatefulWidget {
  const _SyncTile();

  @override
  ConsumerState<_SyncTile> createState() => _SyncTileState();
}

class _SyncTileState extends ConsumerState<_SyncTile> {
  bool _syncing = false;

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context);
    final authorized =
        ref.read(authStatusProvider).asData?.value?.authorized ?? false;
    if (!authorized) {
      _toast(context, l10n.syncNotAuthorized);
      return;
    }
    setState(() => _syncing = true);
    try {
      final outcome = await performSync();
      if (!mounted) return;
      ref.invalidate(syncStateProvider);
      ref.invalidate(authStatusProvider);
      invalidateAnalytics(ref);
      _toast(
        context,
        outcome.success
            ? '${l10n.syncDone} · ${outcome.records}'
            : '${l10n.syncFailed}: ${outcome.message ?? ''}',
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authorized =
        ref.watch(authStatusProvider).asData?.value?.authorized ?? false;
    final syncState = ref.watch(syncStateProvider).asData?.value;
    final lastSync = syncState?.lastSync;
    final subtitle = !authorized
        ? l10n.syncNotAuthorized
        : _syncing
        ? l10n.syncing
        : lastSync == null
        ? l10n.syncWindowFirst
        : '${l10n.lastSyncAt(formatSyncTime(lastSync))} · ${l10n.syncWindow180Short}';

    return ListTile(
      leading: const Icon(Icons.sync),
      title: Text(l10n.syncNow),
      subtitle: Text(subtitle),
      trailing: _syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(authorized ? Icons.chevron_right : Icons.lock_outline),
      onTap: authorized && !_syncing ? _sync : null,
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(l10n.settingsPrivacy),
      subtitle: Text(l10n.localOnly),
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.lock_outline),
            title: Text(l10n.privacySectionTitle),
            content: Text(l10n.privacySectionBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum AuthOutcome { success, denied, expired, failed, cancelled }

/// 打开浏览器完成官方授权，并在对话框里轮询结果。
class _AuthDialog extends StatefulWidget {
  const _AuthDialog();

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  rust.AuthStartDto? _start;
  Timer? _pollTimer;
  Timer? _expiryTimer;
  bool _finished = false;
  bool _polling = false;
  bool _openFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _begin();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _begin() async {
    final l10n = AppLocalizations.of(context);
    final rust.AuthStartDto start;
    try {
      start = rust.authStart();
    } catch (_) {
      if (mounted) {
        setState(() => _error = l10n.authStartFailed);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _start = start);
    _expiryTimer = Timer(
      Duration(seconds: start.expiresInSeconds.toInt()),
      () => _finish(AuthOutcome.expired),
    );
    try {
      final opened = await launchUrl(
        Uri.parse(start.url),
        mode: LaunchMode.externalApplication,
      );
      if (mounted && !opened) setState(() => _openFailed = true);
    } catch (_) {
      if (mounted) setState(() => _openFailed = true);
    }
    if (!mounted) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_polling || _finished) return;
    final start = _start;
    if (start == null) return;
    _polling = true;
    try {
      final result = rust.authPoll(
        state: start.state,
        claimSecret: start.claimSecret,
      );
      switch (result.status) {
        case 'ready':
          _finish(AuthOutcome.success);
          break;
        case 'denied':
          _finish(AuthOutcome.denied);
          break;
        case 'expired':
          _finish(AuthOutcome.expired);
          break;
        case 'failed':
          _finish(AuthOutcome.failed);
          break;
      }
    } catch (_) {
      // 网络抖动时继续轮询，等下一次结果。
    } finally {
      _polling = false;
    }
  }

  void _finish(AuthOutcome outcome) {
    if (_finished) return;
    _finished = true;
    _pollTimer?.cancel();
    _expiryTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _copyLink() async {
    final start = _start;
    if (start == null) return;
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: start.url));
    if (!mounted) return;
    _toast(context, l10n.authLinkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.connectZepp),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.authWaiting, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                l10n.authHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_openFailed) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.authOpenFailed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (_start != null) ...[
                const SizedBox(height: 10),
                Text(
                  _start!.url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_start != null)
          TextButton.icon(
            onPressed: _copyLink,
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.authCopyLink),
          ),
        TextButton(
          onPressed: () => _finish(AuthOutcome.cancelled),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
