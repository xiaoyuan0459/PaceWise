import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pacebridge/features/compare/compare_page.dart';
import 'package:pacebridge/features/overview/overview_page.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('overview shows the empty state', (tester) async {
    await tester.pumpWidget(wrap(const OverviewPage()));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('No training data yet'), findsOneWidget);
    expect(find.text('Connect Zepp'), findsOneWidget);
  });

  testWidgets('compare switches between windows', (tester) async {
    await tester.pumpWidget(wrap(const ComparePage()));
    await tester.pumpAndSettle();

    expect(find.text('90 days'), findsOneWidget);
    await tester.tap(find.text('180 days'));
    await tester.pumpAndSettle();
    expect(find.text('Analysis engine ready'), findsOneWidget);
  });
}
