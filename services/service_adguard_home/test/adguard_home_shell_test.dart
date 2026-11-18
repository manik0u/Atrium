import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_adguard_home/service_adguard_home.dart';

import 'support/adguard_home_test_instance.dart';
import 'support/pump.dart';

void main() {
  final DateTime readAt = DateTime(2026, 10, 7, 18, 30);

  final AdguardHomeStatus status = AdguardHomeStatus(
    version: 'v0.107.79',
    running: true,
    protectionEnabled: true,
    pauseLeft: Duration.zero,
    readAt: readAt,
  );

  final AdguardHomeQueryLogState log = AdguardHomeQueryLogState(
    entries: <AdguardHomeQueryLogEntry>[
      AdguardHomeQueryLogEntry(
        domain: 'example.org',
        reason: 'NotFilteredNotFound',
        time: readAt.toUtc(),
        type: 'A',
        client: '172.17.0.1',
      ),
    ],
    reachedEnd: true,
  );

  Future<Pumped> pumpShell(WidgetTester tester, {Object? clientsError}) =>
      pumpAdguardHome(
        tester,
        const AdguardHomeShell(instance: adguardHomeTestInstance),
        status: status,
        log: log,
        clientsError: clientsError,
        size: const Size(360, 900),
      );

  /// The destination of the bottom bar named [label].
  Finder destination(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  int selected(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  Future<void> openLog(WidgetTester tester) async {
    await tester.tap(destination('Journal des requêtes'));
    await tester.pump();
    await tester.pump();
  }

  Future<void> openClients(WidgetTester tester) async {
    await tester.tap(destination('Clients'));
    await tester.pump();
    await tester.pump();
  }

  final Finder addClient =
      find.widgetWithText(FloatingActionButton, 'Ajouter un client');

  testWidgets('opens on Home, with Home, Query log, Filters, Clients and '
      'Settings in the bar, in that order', (WidgetTester tester) async {
    await pumpShell(tester);

    expect(destination('Accueil'), findsOneWidget);
    expect(destination('Journal des requêtes'), findsOneWidget);
    expect(destination('Filtres'), findsOneWidget);
    expect(destination('Clients'), findsOneWidget);
    expect(destination('Paramètres'), findsOneWidget);
    expect(
      tester.getCenter(destination('Filtres')).dx,
      lessThan(tester.getCenter(destination('Clients')).dx),
    );
    expect(
      tester.getCenter(destination('Clients')).dx,
      lessThan(tester.getCenter(destination('Paramètres')).dx),
    );
    expect(
      tester.getCenter(destination('Journal des requêtes')).dx,
      lessThan(tester.getCenter(destination('Filtres')).dx),
    );
    expect(selected(tester), 0);
    expect(find.text('La protection est activée'), findsOneWidget);
  });

  group('the filters', () {
    Future<void> openFilters(WidgetTester tester) async {
      await tester.tap(destination('Filtres'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('are not read until their tab is opened, then shown',
        (WidgetTester tester) async {
      final Pumped pumped = await pumpShell(tester);
      expect(pumped.rewriteReads, 0);
      expect(pumped.globalServicesReads, 0);

      await openFilters(tester);

      expect(selected(tester), 2);
      expect(find.text('Listes de blocage'), findsOneWidget);
      expect(pumped.rewriteReads, 1);
      expect(pumped.globalServicesReads, 1);
    });

    testWidgets('back on their tab goes to Home before it leaves',
        (WidgetTester tester) async {
      await pumpShell(tester);
      await openFilters(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(selected(tester), 0);
    });

    testWidgets('have no add button and no query log menu',
        (WidgetTester tester) async {
      await pumpShell(tester);
      await openFilters(tester);

      expect(addClient, findsNothing);
      expect(find.byTooltip('Plus'), findsNothing);
    });
  });

  group('the settings', () {
    testWidgets('read nothing of their own when their tab is opened',
        (WidgetTester tester) async {
      final Pumped pumped = await pumpShell(tester);

      await tester.tap(destination('Paramètres'));
      await tester.pump();
      await tester.pump();

      expect(selected(tester), 4);
      expect(find.text('Général'), findsOneWidget);
      expect(find.text('Statistiques'), findsOneWidget);
      expect(pumped.settingsReads, 0);
      expect(addClient, findsNothing);
      expect(find.byTooltip('Plus'), findsNothing);
    });
  });

  group('the clients', () {
    testWidgets('are not asked for until their tab is opened',
        (WidgetTester tester) async {
      // Three requests nobody is waiting for, otherwise.
      final Pumped pumped = await pumpShell(tester);
      await openLog(tester);
      expect(pumped.clientReads, 0);

      await openClients(tester);

      expect(pumped.clientReads, 1);
      expect(selected(tester), 3);
      expect(find.text('Persistent (3)'), findsOneWidget);
    });

    testWidgets('keep their place while another tab is shown',
        (WidgetTester tester) async {
      final Pumped pumped = await pumpShell(tester);
      await openClients(tester);

      await tester.tap(destination('Accueil'));
      await tester.pump();
      await openClients(tester);

      expect(pumped.clientReads, 1);
      expect(
        find.byType(AdguardHomeClientsTab, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('can be added to from their tab, and from no other',
        (WidgetTester tester) async {
      await pumpShell(tester);
      expect(addClient, findsNothing);
      await openLog(tester);
      expect(addClient, findsNothing);

      await openClients(tester);

      expect(addClient, findsOneWidget);
    });

    testWidgets('the add button opens the form for a new client, with the '
        'tags the server offers', (WidgetTester tester) async {
      await pumpShell(tester);
      await openClients(tester);
      // The button grows in, and cannot be tapped until it has.
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(addClient);
      await tester.pumpAndSettle();

      expect(find.text('Nouveau client'), findsOneWidget);
      expect(
        tester
            .widget<AdguardHomeClientScreen>(
              find.byType(AdguardHomeClientScreen),
            )
            .supportedTags,
        hasLength(21),
      );
    });

    testWidgets('cannot be added to while they cannot be read',
        (WidgetTester tester) async {
      // There would be no tags to offer, and after a refused sign-in
      // nothing could be saved.
      await pumpShell(tester, clientsError: const AdguardHomeSignInRefused());
      await openClients(tester);

      expect(find.byType(AdguardHomeRefusedView), findsOneWidget);
      expect(addClient, findsNothing);
    });

    testWidgets('back on their tab goes to Home before it leaves',
        (WidgetTester tester) async {
      await pumpShell(tester);
      await openClients(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(selected(tester), 0);
      expect(find.text('La protection est activée'), findsOneWidget);
    });

    testWidgets('have no menu for the query log over them',
        (WidgetTester tester) async {
      await pumpShell(tester);
      await openClients(tester);

      expect(find.byTooltip('Plus'), findsNothing);
    });
  });

  testWidgets('the query log is not asked for until its tab is opened',
      (WidgetTester tester) async {
    // Opening the service must not cost a scan of the log nobody looks at.
    final Pumped pumped = await pumpShell(tester);
    expect(pumped.logWatched, isFalse);

    await openLog(tester);

    expect(pumped.logWatched, isTrue);
    expect(selected(tester), 1);
    expect(find.text('example.org'), findsOneWidget);
  });

  testWidgets('the query log keeps its place while Home is shown',
      (WidgetTester tester) async {
    await pumpShell(tester);
    await openLog(tester);

    await tester.tap(destination('Accueil'));
    await tester.pump();

    expect(selected(tester), 0);
    expect(
      find.byType(AdguardHomeQueryLogTab, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('back on the query log goes to Home before it leaves',
      (WidgetTester tester) async {
    await pumpShell(tester);
    await openLog(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(selected(tester), 0);
    expect(find.text('La protection est activée'), findsOneWidget);
  });

  group('clearing the log', () {
    testWidgets('is offered on the Query log tab only',
        (WidgetTester tester) async {
      await pumpShell(tester);
      expect(find.byTooltip('Plus'), findsNothing);

      await openLog(tester);

      expect(find.byTooltip('Plus'), findsOneWidget);
    });

    testWidgets('asks first, and Cancel clears nothing',
        (WidgetTester tester) async {
      final Pumped pumped = await pumpShell(tester);
      await openLog(tester);

      await tester.tap(find.byTooltip('Plus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Effacer le journal des requêtes'));
      await tester.pumpAndSettle();

      expect(find.text('Effacer le journal des requêtes ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(pumped.actions.calls, isEmpty);
      expect(pumped.log.calls, isEmpty);
    });

    testWidgets('once confirmed it clears, says so and reads the log again',
        (WidgetTester tester) async {
      final Pumped pumped = await pumpShell(tester);
      await openLog(tester);

      await tester.tap(find.byTooltip('Plus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Effacer le journal des requêtes'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Effacer'));
      await tester.pumpAndSettle();

      expect(pumped.actions.calls, <String>['clear log']);
      expect(pumped.log.calls, <String>['reload']);
      expect(find.text('Query log cleared'), findsOneWidget);
    });

    testWidgets('a clear the server turns down says why and reads nothing',
        (WidgetTester tester) async {
      final Pumped pumped = await pumpShell(tester);
      await openLog(tester);
      pumped.actions.writeFailure = const AdguardHomeRequestRefused('not now');

      await tester.tap(find.byTooltip('Plus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Effacer le journal des requêtes'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Effacer'));
      await tester.pumpAndSettle();

      expect(find.text('not now'), findsOneWidget);
      expect(pumped.log.calls, isEmpty);
    });
  });
}
