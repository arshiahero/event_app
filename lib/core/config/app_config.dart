import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real services are deliberately not assigned a default URL.
class AppConfig {
  AppConfig({
    this.useMocks = true,
    this.enableImages = true,
    this.apiBaseUri,
    this.debugNetworkLogs = false,
  }) {
    final uri = apiBaseUri;
    if (uri != null &&
        (uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty ||
            uri.hasQuery ||
            uri.hasFragment ||
            !uri.path.endsWith('/'))) {
      throw ArgumentError(
        'apiBaseUri must be HTTPS with a host, trailing slash, and no credentials, query or fragment.',
      );
    }
    if (!useMocks && uri == null) {
      throw ArgumentError('Real mode requires apiBaseUri.');
    }
  }

  final bool useMocks;
  final bool enableImages;
  final Uri? apiBaseUri;
  final bool debugNetworkLogs;
}

/// Override at ProviderScope to explicitly opt into configured real services.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig());
