import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_adguard_home/service_adguard_home.dart';

import 'support/adguard_home_test_instance.dart';
import 'support/pump.dart';

void main() {
  final Finder save = find.widgetWithText(FilledButton, 'Enregistrer');
  final Finder hours = find.byKey(const Key('adguard-retention-hours'));
  final Finder ignored = find.byKey(const Key('adguard-retention-ignored'));

  /// Opens the screen over a plain one, as the Settings tab does, so it can
  /// close itself.
  Future<Pumped> open(
    WidgetTester tester,
    AdguardHomeRetentionKind kind, {
    AdguardHomeRetention? queryLog,
    AdguardHomeRetention? stats,
    Size size = const Size(360, 1800),
    double textScale = 1,
  }) async {
    final Pumped pumped = await pumpAdguardHome(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => AdguardHomeRetentionScreen(
                instance: adguardHomeTestInstance,
                kind: kind,
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
      queryLogRetention: queryLog,
      statsRetention: stats,
      size: size,
      textScale: textScale,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return pumped;
  }

  bool picked(WidgetTester tester, String label) =>
      tester
          .widget<RadioGroup<int>>(find.byType(RadioGroup<int>))
          .groupValue ==
      tester
          .widget<RadioListTile<int>>(
            find.widgetWithText(RadioListTile<int>, label),
          )
          .value;

  testWidgets('the query log opens as the server has it',
      (WidgetTester tester) async {
    await open(tester, AdguardHomeRetentionKind.queryLog);

    expect(find.text('Journal des requêtes'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Conserver un journal des requêtes'),
          )
          .value,
      isTrue,
    );
    expect(find.text("Anonymiser l'IP du client"), findsOneWidget);
    expect(picked(tester, '90 days'), isTrue);
    expect(find.text('6 hours'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('statistics have no anonymising, and no 6 hours',
      (WidgetTester tester) async {
    await open(tester, AdguardHomeRetentionKind.statistics);

    expect(find.text("Anonymiser l'IP du client"), findsNothing);
    expect(find.text('6 hours'), findsNothing);
    expect(picked(tester, '24 hours'), isTrue);
    expect(find.text('Réinitialiser les statistiques'), findsOneWidget);
  });

  testWidgets('a shorter retention asks first, then saves and closes',
      (WidgetTester tester) async {
    final Pumped pumped = await open(tester, AdguardHomeRetentionKind.queryLog);

    await tester.tap(find.text('7 days'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Conserver le journal moins longtemps ?'), findsOneWidget);
    expect(find.textContaining('older than 7 days'), findsOneWidget);
    expect(pumped.actions.calls, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer').last);
    await tester.pumpAndSettle();

    expect(pumped.actions.calls, <String>['querylog settings']);
    expect(
      pumped.actions.savedRetention.single.interval,
      const Duration(days: 7),
    );
    expect(find.byType(AdguardHomeRetentionScreen), findsNothing);
    expect(find.text('Query log settings saved'), findsOneWidget);
  });

  testWidgets('Cancel on the question sends nothing and stays',
      (WidgetTester tester) async {
    final Pumped pumped = await open(tester, AdguardHomeRetentionKind.queryLog);

    await tester.tap(find.text('24 hours'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(pumped.actions.calls, isEmpty);
    expect(find.byType(AdguardHomeRetentionScreen), findsOneWidget);
  });

  testWidgets('a longer retention saves without asking',
      (WidgetTester tester) async {
    final Pumped pumped =
        await open(tester, AdguardHomeRetentionKind.statistics);

    await tester.tap(find.text('30 days'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(pumped.actions.calls, <String>['stats settings']);
    expect(find.text('Statistics settings saved'), findsOneWidget);
  });

  testWidgets('a custom retention is in whole hours, from 1 to a year',
      (WidgetTester tester) async {
    final Pumped pumped =
        await open(tester, AdguardHomeRetentionKind.statistics);

    await tester.tap(find.text('Personnalisé'));
    await tester.pump();
    expect(tester.widget<TextField>(hours).controller!.text, '24');

    await tester.enterText(hours, '0');
    await tester.pump();
    expect(find.text('From 1 to 8760 hours.'), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(pumped.actions.calls, isEmpty);

    await tester.enterText(hours, '48');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      pumped.actions.savedRetention.single.interval,
      const Duration(hours: 48),
    );
  });

  testWidgets('a retention not among the choices opens as Custom',
      (WidgetTester tester) async {
    await open(
      tester,
      AdguardHomeRetentionKind.queryLog,
      queryLog: const AdguardHomeRetention(
        interval: Duration(hours: 5),
        anonymizeClientIp: false,
      ),
    );

    expect(picked(tester, 'Personnalisé'), isTrue);
    expect(tester.widget<TextField>(hours).controller!.text, '5');
  });

  testWidgets('ignored domains are saved one a line, blank lines dropped',
      (WidgetTester tester) async {
    final Pumped pumped = await open(tester, AdguardHomeRetentionKind.queryLog);

    await tester.tap(find.text('Exclure ces domaines'));
    await tester.pump();
    await tester.enterText(ignored, 'a.example\n\n *.b.example \n');
    await tester.pump();
    await tester.tap(find.text("Anonymiser l'IP du client"));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final AdguardHomeRetention sent = pumped.actions.savedRetention.single;
    expect(sent.ignored, <String>['a.example', '*.b.example']);
    expect(sent.ignoredEnabled, isTrue);
    expect(sent.anonymizeClientIp, isTrue);
    expect(sent.interval, const Duration(days: 90));
  });

  testWidgets('leaving with a change asks first', (WidgetTester tester) async {
    await open(tester, AdguardHomeRetentionKind.queryLog);

    await tester.tap(find.text('Conserver un journal des requêtes'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Ignorer les modifications ?'), findsOneWidget);
    await tester.tap(find.text('Ignorer'));
    await tester.pumpAndSettle();
    expect(find.byType(AdguardHomeRetentionScreen), findsNothing);
  });

  testWidgets('a save refused for the sign-in can be tried again',
      (WidgetTester tester) async {
    final Pumped pumped =
        await open(tester, AdguardHomeRetentionKind.statistics);
    pumped.actions.writeFailure = const AdguardHomeSignInRefused();

    await tester.tap(find.text('Conserver les statistiques'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Réessayer'));
    await tester.pumpAndSettle();

    expect(
      pumped.actions.calls,
      <String>['stats settings', 'retry', 'stats settings'],
    );
    expect(find.text('Statistics settings saved'), findsOneWidget);
  });

  testWidgets('Try again after a refused sign-in does not ask about the '
      'shorter retention twice', (WidgetTester tester) async {
    final Pumped pumped = await open(tester, AdguardHomeRetentionKind.queryLog);
    pumped.actions.writeFailure = const AdguardHomeSignInRefused();

    await tester.tap(find.text('7 days'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Conserver le journal moins longtemps ?'), findsNothing);
    expect(
      pumped.actions.calls,
      <String>['querylog settings', 'retry', 'querylog settings'],
    );
  });

  testWidgets('a retention of no whole hours stays as the server has it',
      (WidgetTester tester) async {
    const Duration odd = Duration(hours: 36, minutes: 30);
    final Pumped pumped = await open(
      tester,
      AdguardHomeRetentionKind.statistics,
      stats: const AdguardHomeRetention(interval: odd),
    );

    expect(picked(tester, 'Personnalisé'), isTrue);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.tap(find.text('Conserver les statistiques'));
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Keep statistics for less time?'), findsNothing);
    expect(pumped.actions.savedRetention.single.interval, odd);
  });

  testWidgets('a server without the ignored switch shows none',
      (WidgetTester tester) async {
    await open(
      tester,
      AdguardHomeRetentionKind.queryLog,
      queryLog: AdguardHomeRetention.fromJson(<String, dynamic>{
        'enabled': true,
        'interval': 86400000,
        'ignored': <String>['a.example'],
        'anonymize_client_ip': false,
      }),
    );

    expect(find.text('Exclure ces domaines'), findsNothing);
    expect(
      find.text(
        'Les requêtes correspondant à ces règles ne sont pas écrites dans le journal',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Clear query log asks, and reads no log that is not open',
      (WidgetTester tester) async {
    final Pumped pumped = await open(tester, AdguardHomeRetentionKind.queryLog);

    await tester.tap(find.text('Effacer le journal des requêtes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(pumped.actions.calls, isEmpty);

    await tester.tap(find.text('Effacer le journal des requêtes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Effacer'));
    await tester.pumpAndSettle();

    expect(pumped.actions.calls, <String>['clear log']);
    expect(pumped.logWatched, isFalse);
  });

  testWidgets('a reset refused for the sign-in offers Try again',
      (WidgetTester tester) async {
    final Pumped pumped =
        await open(tester, AdguardHomeRetentionKind.statistics);
    pumped.actions.writeFailure = const AdguardHomeSignInRefused();

    await tester.tap(find.text('Réinitialiser les statistiques'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Réinitialiser'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, 'Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Réinitialiser les statistiques ?'), findsNothing);
    expect(
      pumped.actions.calls,
      <String>['reset stats', 'retry', 'reset stats'],
    );
    expect(find.text('Statistiques réinitialisées'), findsOneWidget);
  });

  testWidgets('a clear of the log refused for the sign-in offers Try again',
      (WidgetTester tester) async {
    final Pumped pumped = await open(tester, AdguardHomeRetentionKind.queryLog);
    pumped.actions.writeFailure = const AdguardHomeSignInRefused();

    await tester.tap(find.text('Effacer le journal des requêtes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Effacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, 'Réessayer'));
    await tester.pumpAndSettle();

    expect(
      pumped.actions.calls,
      <String>['clear log', 'retry', 'clear log'],
    );
    expect(find.text('Query log cleared'), findsOneWidget);
  });

  testWidgets('resetting statistics asks first', (WidgetTester tester) async {
    final Pumped pumped =
        await open(tester, AdguardHomeRetentionKind.statistics);

    await tester.tap(find.text('Réinitialiser les statistiques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(pumped.actions.calls, isEmpty);

    await tester.tap(find.text('Réinitialiser les statistiques'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Réinitialiser'));
    await tester.pumpAndSettle();

    expect(pumped.actions.calls, <String>['reset stats']);
    expect(find.text('Statistiques réinitialisées'), findsOneWidget);
  });

  for (final double width in <double>[320, 411]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets('layout holds at $width wide and $scale text',
          (WidgetTester tester) async {
        await open(
          tester,
          AdguardHomeRetentionKind.queryLog,
          size: Size(width, 2400),
          textScale: scale,
        );
        await tester.tap(find.text('Personnalisé'));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
