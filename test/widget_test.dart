import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:event_app/app.dart';
import 'package:event_app/core/shared.dart';
import 'package:event_app/data/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('DM Sans')
      ..addFont(rootBundle.load('assets/fonts/DMSans.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 451.0, 800.0, 801.0, 1440.0]) {
    testWidgets('All main routes render at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      appRouter.go('/');
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        oldHandler!(details);
      };
      await tester.pumpWidget(const ProviderScope(child: EventApp()));
      for (final path in [
        '/',
        '/search',
        '/search/results?q=Candlelight',
        '/discover',
        '/tickets',
        '/tickets/FEV-2097544',
        '/profile',
        '/profile/preferences',
        '/profile/favourites',
        '/profile/help',
        '/event/1',
        '/event/missing',
        '/event/1/book',
        '/login',
        '/register',
      ]) {
        appRouter.go(path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: path);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  test('GBP currency keeps pennies', () {
    expect(currency(27), '£27.00');
    expect(currency(19.5), '£19.50');
    expect(currency(275), '£275.00');
  });
  test('Reservation total and Gregorian start time', () {
    final r = Reservation(
      id: 'test',
      event: events.first,
      date: DateTime(2026, 10, 24),
      time: '19:00',
      type: 'Standard',
      quantity: 2,
    );
    expect(r.total, 54);
    expect(r.startsAt, DateTime(2026, 10, 24, 19));
    expect(isoDate(r.date), '2026-10-24');
    expect(dateLabel(r.date), 'Sat 24 Oct');
  });
  test('Theme matches document tokens', () {
    expect(AppColors.background, const Color(0xFF0A1A1A));
    expect(AppColors.primary, const Color(0xFFE8A838));
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.textTheme.bodyMedium!.fontFamily, 'DM Sans');
    expect(AppDimensions.pagePadding(450), 20);
    expect(AppDimensions.pagePadding(451), 40);
    expect(AppDimensions.pagePadding(801), 80);
  });
  testWidgets('Home renders English LTR and one brand', (tester) async {
    appRouter.go('/');
    await tester.pumpWidget(const ProviderScope(child: EventApp()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('For you'), findsOneWidget);
    expect(find.text('GOOD PLANS START HERE'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AppShell))),
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
