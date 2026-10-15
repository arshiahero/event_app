import 'package:event_app/app.dart';
import 'package:event_app/core/shared.dart';
import 'package:event_app/data/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _pump(tester);
}

Future<ProviderContainer> _start(
  WidgetTester tester,
  String route, {
  DateTime? date,
}) async {
  final oldErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint('${details.library}: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack, maxFrames: 12);
    oldErrorHandler!(details);
  };
  addTearDown(() => FlutterError.onError = oldErrorHandler);
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      if (date != null) filterDateProvider.overrideWith((ref) => date),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  appRouter.go('/');
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EventApp()),
  );
  await _pump(tester);

  appRouter.go(route);
  await _pump(tester);
  expect(tester.takeException(), isNull, reason: 'Opening $route');
  return container;
}

Finder _dialogText(String text) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(text));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('DM Sans')
      ..addFont(rootBundle.load('assets/fonts/DMSans.ttf'));
    await loader.load();
  });

  testWidgets('Booking confirms chosen details once and opens ticket card', (
    tester,
  ) async {
    final initialDate = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 10)),
    );
    final chosenDate = initialDate.add(const Duration(days: 1));
    final container = await _start(tester, '/event/1/book', date: initialDate);
    final before = List<Reservation>.of(container.read(ticketsProvider));
    expect(find.text('Total (2 tickets)'), findsOneWidget);
    expect(find.text('£54.00'), findsOneWidget);
    await _tap(tester, find.byTooltip('Add ticket'));
    expect(find.text('Total (3 tickets)'), findsOneWidget);
    expect(find.text('£81.00'), findsOneWidget);
    await _tap(tester, find.text('21:00'));

    await _tap(tester, find.text(shortDate(initialDate)));
    await _tap(tester, find.byIcon(Icons.edit_outlined));
    final dateInput = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(
      dateInput,
      MaterialLocalizations.of(
        tester.element(dateInput),
      ).formatCompactDate(chosenDate),
    );
    await _tap(tester, find.text('OK'));
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.text(shortDate(chosenDate)), findsOneWidget);

    await _tap(tester, find.text('Get tickets →'));
    expect(_dialogText(events.first.title), findsOneWidget);
    expect(_dialogText('${isoDate(chosenDate)} · 21:00'), findsOneWidget);
    expect(_dialogText('3 × Standard'), findsOneWidget);
    expect(_dialogText('General admission'), findsOneWidget);
    expect(_dialogText('£81.00'), findsOneWidget);
    expect(container.read(ticketsProvider), orderedEquals(before));

    // Two taps before rebuilding exercise the confirmation's insertion guard.
    final confirm = _dialogText('Confirm sample reservation →');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.tap(confirm);
    await _pump(tester);
    final tickets = container.read(ticketsProvider);
    expect(tickets, hasLength(before.length + 1));
    expect(tickets.take(before.length), orderedEquals(before));
    final reservation = tickets.last;
    expect(reservation.event, same(events.first));
    expect(reservation.date, chosenDate);
    expect(reservation.quantity, 3);
    expect(reservation.time, '21:00');
    expect(reservation.type, 'Standard');
    expect(reservation.total, 81);
    expect(_dialogText('A good plan is on the cards.'), findsOneWidget);
    expect(
      _dialogText('${dateLabel(chosenDate)} · 21:00 · 3 × Standard'),
      findsOneWidget,
    );
    await _tap(tester, _dialogText('View my tickets →'));
    expect(appRouter.routeInformationProvider.value.uri.path, '/tickets');
    expect(find.text('Your tickets'), findsOneWidget);
    expect(find.text(events.first.title), findsOneWidget);
    expect(find.text('${isoDate(chosenDate)} · 21:00'), findsOneWidget);
    expect(find.text('3 tickets · Standard'), findsOneWidget);
    expect(container.read(ticketsProvider), hasLength(before.length + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Closing reservation review does not insert a ticket', (
    tester,
  ) async {
    final container = await _start(tester, '/event/1/book');
    final before = List<Reservation>.of(container.read(ticketsProvider));
    await _tap(tester, find.byTooltip('Add ticket'));
    await _tap(tester, find.text('Get tickets →'));
    expect(_dialogText('Your experience, all set.'), findsOneWidget);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byTooltip('Close'),
      ),
    );
    expect(find.byType(Dialog), findsNothing);
    expect(container.read(ticketsProvider), orderedEquals(before));
    expect(find.text('Total (3 tickets)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preferences update interests and checkbox session state', (
    tester,
  ) async {
    final container = await _start(tester, '/profile/preferences');
    expect(container.read(interestsProvider), {'Live Music'});
    await _tap(tester, find.text('Culture'));
    expect(container.read(interestsProvider), {'Live Music', 'Culture'});
    await _tap(tester, find.text('Live Music'));
    expect(container.read(interestsProvider), {'Culture'});
    await _tap(tester, find.text('Culture'));
    expect(container.read(interestsProvider), isEmpty);
    await _tap(tester, find.text('Good plans in your inbox'));
    expect(container.read(emailProvider), isTrue);
    await _tap(tester, find.text('Experience reminders'));
    expect(container.read(remindersProvider), isFalse);
    appRouter.go('/profile');
    await _pump(tester);
    appRouter.go('/profile/preferences');
    await _pump(tester);
    final boxes = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(boxes.map((box) => box.value), orderedEquals([true, false]));
    expect(container.read(interestsProvider), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Selecting Barcelona limits discovery to Primavera', (
    tester,
  ) async {
    final container = await _start(tester, '/discover');
    await _tap(tester, find.widgetWithText(TextButton, 'London'));
    await _tap(tester, find.widgetWithText(ListTile, 'Barcelona'));
    expect(container.read(cityProvider), 'Barcelona');
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is GoldPeriodTitle && widget.text == 'Discover Barcelona',
      ),
      findsOneWidget,
    );
    final cards = tester.widgetList<EventCard>(find.byType(EventCard)).toList();
    expect(cards.map((card) => card.event.id), orderedEquals(['3']));
    expect(find.text('Primavera Sound Barcelona 2027'), findsOneWidget);
    expect(find.text(events.first.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filter drafts cancel unchanged, apply and reset explicitly', (
    tester,
  ) async {
    final container = await _start(tester, '/discover');
    Future<void> open() => _tap(
      tester,
      find.widgetWithText(
        OutlinedButton,
        container.read(categoryProvider) == 'All'
            ? 'Category'
            : container.read(categoryProvider),
      ),
    );
    Future<void> draft() async {
      final sheet = find.byType(BottomSheet);
      await _tap(
        tester,
        find.descendant(of: sheet, matching: find.text('Culture')),
      );
      final slider = find.descendant(of: sheet, matching: find.byType(Slider));
      await tester.ensureVisible(slider);
      await tester.pump();
      await tester.tapAt(tester.getCenter(slider));
      await _pump(tester);
      expect(tester.widget<Slider>(slider).value, 150);
    }

    await open();
    await draft();
    expect(container.read(categoryProvider), 'All');
    expect(container.read(maxPriceProvider), 300);
    await _tap(tester, find.byTooltip('Close'));
    expect(container.read(categoryProvider), 'All');
    expect(container.read(maxPriceProvider), 300);
    await open();
    await draft();
    await _tap(tester, find.text('✓ Apply filters'));
    expect(container.read(categoryProvider), 'Culture');
    expect(container.read(maxPriceProvider), 150);
    expect(
      tester
          .widgetList<EventCard>(find.byType(EventCard))
          .map((c) => c.event.id),
      unorderedEquals(['2', '8']),
    );
    await open();
    await _tap(tester, find.text('Reset'));
    expect(container.read(categoryProvider), 'Culture');
    expect(container.read(maxPriceProvider), 150);
    await _tap(tester, find.text('✓ Apply filters'));
    expect(container.read(categoryProvider), 'All');
    expect(container.read(maxPriceProvider), 300);
    expect(container.read(filterDateProvider), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Live search debounces Coldplay and shares favourites', (
    tester,
  ) async {
    final container = await _start(tester, '/search');
    final input = find.byType(TextField);
    await tester.enterText(input, 'Cold');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(input, 'Coldplay');
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.text('Coldplay — 1 experiences'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('Coldplay — 1 experiences'), findsOneWidget);
    expect(find.text(events.first.title), findsOneWidget);
    for (final event in events.skip(1)) {
      expect(find.text(event.title), findsNothing);
    }
    await _tap(tester, find.text(events.first.title));
    expect(find.text('Choose your time'), findsOneWidget);
    await _tap(
      tester,
      find.byTooltip('Save to favourites').hitTestable().first,
    );
    expect(container.read(favoritesProvider), {'1'});
    appRouter.go('/profile/favourites');
    await _pump(tester);
    expect(find.text(events.first.title), findsOneWidget);
    await _tap(tester, find.byTooltip('Remove from favourites'));
    expect(container.read(favoritesProvider), isEmpty);
    expect(find.byType(EventCard), findsNothing);
    appRouter.go('/event/1');
    await _pump(tester);
    expect(find.byTooltip('Save to favourites').hitTestable(), findsWidgets);
    expect(container.read(favoritesProvider), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
