import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_app/app.dart';
import 'package:event_app/core/shared.dart';
import 'package:event_app/data/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'DM Sans',
    )..addFont(rootBundle.load('assets/fonts/DMSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final preview in [
    ('home_mobile', '/', 390.0),
    ('home_desktop', '/', 1440.0),
    ('search_mobile', '/search', 390.0),
  ]) {
    testWidgets('${preview.$1} visual regression', (tester) async {
      tester.view.physicalSize = Size(preview.$3, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      appRouter.go(preview.$2);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(key: Key('preview'), child: EventApp()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final context = tester.element(find.byType(EventApp));
      await tester.runAsync(() async {
        for (final image in events.expand((e) => e.images).toSet()) {
          await precacheImage(AssetImage(image), context);
        }
      });
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('preview')),
        matchesGoldenFile('goldens/${preview.$1}.png'),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
}
