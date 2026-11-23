import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.settingsDataDir),
              subtitle: Text(l10n.settingsAppData),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsPrivacy),
              subtitle: Text(l10n.localOnly),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              subtitle: Text('${l10n.version} 3.2.1'),
            ),
          ]),
        ),
      ],
    );
  }
}
