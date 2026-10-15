import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import 'auth_models.dart';
import 'auth_provider.dart';

/// Opt-in GoRouter redirect. All application paths are supplied by the caller.
class AuthGuard {
  AuthGuard({
    this.enabled = false,
    this.allowMockGuests = true,
    this.loginLocation,
    Set<String> protectedPaths = const {},
    Set<String> allowedReturnPaths = const {},
  }) : protectedPaths = Set.unmodifiable(protectedPaths),
       allowedReturnPaths = Set.unmodifiable({
         ...protectedPaths,
         ...allowedReturnPaths,
       }) {
    if ((enabled && loginLocation == null) ||
        (loginLocation != null && !_validPath(loginLocation!))) {
      throw ArgumentError(
        'An enabled guard requires an absolute local login path.',
      );
    }
    if (this.protectedPaths.any((path) => !_validPath(path)) ||
        this.allowedReturnPaths.any((path) => !_validPath(path))) {
      throw ArgumentError(
        'Route paths must be absolute local paths without query or fragment.',
      );
    }
  }
  static const returnParameter = 'returnTo';
  final bool enabled;
  final bool allowMockGuests;
  final String? loginLocation;
  final Set<String> protectedPaths;

  /// Exact paths and descendants are allowed. Do not include '/' unless all
  /// application paths are intentionally trusted as return destinations.
  final Set<String> allowedReturnPaths;

  static Uri? _localUri(String value) {
    try {
      if (!value.startsWith('/') ||
          value.startsWith('//') ||
          RegExp(r'[\s\\\x00-\x1f\x7f]').hasMatch(value))
        return null;
      final uri = Uri.parse(value);
      if (uri.hasScheme || uri.hasAuthority || uri.hasFragment) return null;
      final decodedPath = Uri.decodeComponent(uri.path);
      // Reject encoded separators, double encoding and dot traversal rather
      // than relying on potentially different router/browser normalization.
      if (!decodedPath.startsWith('/') ||
          decodedPath.startsWith('//') ||
          decodedPath.contains('//') ||
          decodedPath.contains('%') ||
          RegExp(r'[\s\\\x00-\x1f\x7f]').hasMatch(decodedPath) ||
          RegExp(r'%2f|%5c', caseSensitive: false).hasMatch(uri.path) ||
          decodedPath.split('/').any((part) => part == '.' || part == '..'))
        return null;
      return uri;
    } on FormatException {
      return null;
    }
  }

  static bool _validPath(String value) {
    final uri = _localUri(value);
    return uri != null && !uri.hasQuery;
  }

  static bool _matches(String location, Set<String> paths) => paths.any(
    (path) =>
        location == path ||
        location.startsWith(path.endsWith('/') ? path : '$path/'),
  );

  /// Returns a local, allowlisted path plus its original query, or null.
  /// Rejects absolute/protocol-relative URLs, traversal and login redirect loops.
  String? safeReturnLocation(String? candidate) {
    if (candidate == null) return null;
    final uri = _localUri(candidate);
    if (uri == null ||
        uri.path == loginLocation ||
        !_matches(uri.path, allowedReturnPaths))
      return null;
    return uri.toString();
  }

  String? redirect({
    required Uri location,
    required AsyncValue<AuthUser?> auth,
    required AppConfig config,
  }) {
    if (!enabled || auth.isLoading) return null;
    if (auth.asData?.value != null) {
      if (location.path != loginLocation) return null;
      final values = location.queryParametersAll[returnParameter];
      return values?.length == 1 ? safeReturnLocation(values!.single) : null;
    }
    if ((config.useMocks && allowMockGuests) || location.path == loginLocation)
      return null;
    if (!_matches(location.path, protectedPaths)) return null;
    final target = safeReturnLocation(location.toString());
    return Uri(
      path: loginLocation!,
      queryParameters: target == null ? null : {returnParameter: target},
    ).toString();
  }
}

/// Optional GoRouter.refreshListenable bridge; never starts session restore.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(Ref ref) {
    ref.listen<AsyncValue<AuthUser?>>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  final refresh = AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});
