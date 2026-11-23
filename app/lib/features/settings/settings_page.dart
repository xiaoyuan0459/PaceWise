import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/core.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;

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
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(l10n.settingsAccount),
              subtitle: Text(l10n.settingsNotConnected),
            ),
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
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsPrivacy),
              subtitle: Text(l10n.localOnly),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              subtitle: Text(
                '${l10n.version} 3.2.1 · schema ${appInfo.schemaVersion}',
              ),
            ),
          ]),
        ),
      ],
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
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context);
    try {
      final report = await rust.syncOfficial(days: 90);
      if (!mounted) return;
      final text = report.success
          ? '${l10n.syncDone} · ${report.recordsWritten}'
          : '${l10n.syncFailed}: ${report.message ?? ''}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${l10n.syncFailed}: $error')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.sync),
      title: Text(l10n.syncNow),
      subtitle: Text(_syncing ? l10n.syncing : l10n.syncWindow90),
      trailing: _syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _syncing ? null : _sync,
    );
  }
}
