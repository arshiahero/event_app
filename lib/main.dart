import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/shared.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const ProviderScope(child: EventApp()));
}
