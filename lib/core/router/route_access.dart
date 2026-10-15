import '../../features/auth/auth_guard.dart';

final appAuthGuard = AuthGuard(
  enabled: true,
  allowMockGuests: true,
  loginLocation: '/login',
  protectedPaths: const {'/profile', '/tickets'},
  allowedReturnPaths: const {
    '/profile',
    '/tickets',
    '/event',
    '/search',
    '/discover',
  },
);
