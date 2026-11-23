import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/app/router.dart';
import 'package:pacebridge/app/theme.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

class PaceBridgeApp extends StatelessWidget {
  const PaceBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(lightDynamic),
          darkTheme: buildDarkTheme(darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
