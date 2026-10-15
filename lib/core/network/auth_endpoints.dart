/// All paths are supplied by the integrating backend, never guessed here.
class AuthEndpoints {
  AuthEndpoints({
    required this.signIn,
    required this.register,
    required this.refresh,
    required this.currentUser,
    required this.signOut,
  }) {
    for (final path in [signIn, register, refresh, currentUser, signOut]) {
      final uri = Uri.parse(path);
      if (path.isEmpty ||
          path.startsWith('/') ||
          RegExp(r'[\s\\\x00-\x1f\x7f]').hasMatch(path) ||
          RegExp(r'%2f|%5c|%25', caseSensitive: false).hasMatch(path) ||
          uri.hasScheme ||
          uri.hasAuthority ||
          uri.hasQuery ||
          uri.hasFragment ||
          uri.pathSegments.any((p) => p == '..' || p == '.')) {
        throw ArgumentError(
          'Endpoints must be non-empty relative paths without query, fragment or traversal.',
        );
      }
    }
  }
  final String signIn;
  final String register;
  final String refresh;
  final String currentUser;
  final String signOut;
}
