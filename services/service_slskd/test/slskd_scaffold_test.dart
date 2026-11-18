import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_slskd/service_slskd.dart';

const Instance testInstance = Instance(
  id: 'slskd-1',
  name: 'Home slskd',
  kind: ServiceKind.slskd,
  localUrl: 'http://slskd.local:5030/',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuthApiKey(apiKey: 'secret-key'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SlskdHome renders and switches tabs smoothly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          slskdDownloadsProvider(testInstance).overrideWith((ref) => []),
          slskdUploadsProvider(testInstance).overrideWith((ref) => []),
          slskdApplicationStateProvider(testInstance).overrideWith((ref) => SlskdApplicationState.fromJson({
            'server': {'isLoggedIn': true, 'state': 'Connected'},
          })),
        ],
        child: const MaterialApp(
          home: SlskdHome(instance: testInstance),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Transfers tab is active initially
    expect(find.text('Transferts'), findsWidgets);
    expect(find.text('Aucun transfert dans la file'), findsOneWidget);

    // Switch to Search tab
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();
    expect(find.text('P2P Music Search'), findsOneWidget);

    // Switch to Browse tab
    await tester.tap(find.text('Parcourir'));
    await tester.pumpAndSettle();
    expect(find.text('Explorateur de bibliothèque du pair'), findsOneWidget);

    // Switch to Community tab
    await tester.tap(find.text('Communauté'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byType(SearchBar)),
      findsOneWidget,
    );
    expect(find.text('Direct Messages (0)'), findsOneWidget);

    // Switch to System tab
    await tester.tap(find.text('Système'));
    await tester.pumpAndSettle();
    expect(find.text('Soulseek Network'), findsOneWidget);
  });
}
