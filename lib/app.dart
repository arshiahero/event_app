import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/shared.dart';
import 'core/widgets/account_frame.dart';
import 'core/router/modal_page.dart';
import 'core/router/route_access.dart';
import 'core/config/app_config.dart';
import 'core/session/session_coordinator.dart';
import 'features/auth/auth_provider.dart';
import 'features/discovery.dart';
import 'features/account.dart';
import 'features/extras.dart';
import 'features/event_detail.dart';

CustomTransitionPage<void> _detailPage(
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _routerRefresh = ChangeNotifier();
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: _routerRefresh,
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return appAuthGuard.redirect(
      location: state.uri,
      auth: container.read(authProvider),
      config: container.read(appConfigProvider),
    );
  },
  routes: [
    StatefulShellRoute(
      navigatorContainerBuilder: (context, shell, children) => IndexedStack(
        index: shell.currentIndex,
        children: List.generate(
          children.length,
          (i) => HeroMode(
            enabled: i == shell.currentIndex,
            child: TickerMode(
              enabled: i == shell.currentIndex,
              child: children[i],
            ),
          ),
        ),
      ),
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              pageBuilder: (_, s) =>
                  NoTransitionPage(key: s.pageKey, child: const HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              pageBuilder: (_, s) =>
                  NoTransitionPage(key: s.pageKey, child: const SearchScreen()),
              routes: [
                GoRoute(
                  path: 'results',
                  name: 'searchResults',
                  builder: (_, s) => SearchScreen(
                    initialQuery: s.uri.queryParameters['q'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/discover',
              name: 'discover',
              pageBuilder: (_, s) => NoTransitionPage(
                key: s.pageKey,
                child: const DiscoverScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tickets',
              name: 'tickets',
              pageBuilder: (_, s) => NoTransitionPage(
                key: s.pageKey,
                child: const TicketsScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'ticketDetail',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (_, s) => ModalPage(
                    key: s.pageKey,
                    name: 'ticketDetail',
                    child: TicketDetailScreen(
                      ticketId: s.pathParameters['id']!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder: (_, s) => NoTransitionPage(
                key: s.pageKey,
                child: const ProfileScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'preferences',
                  name: 'preferences',
                  builder: (_, _) => const PreferencesScreen(),
                ),
                GoRoute(
                  path: 'favourites',
                  name: 'favourites',
                  builder: (_, _) => const FavouritesScreen(),
                ),
                GoRoute(
                  path: 'help',
                  name: 'help',
                  builder: (_, _) => const HelpScreen(),
                  routes: [
                    GoRoute(
                      path: 'contact',
                      name: 'contactSupport',
                      builder: (_, _) => const SupportRequestScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'club',
                  name: 'club',
                  builder: (_, _) => const ClubScreen(),
                ),
                GoRoute(
                  path: 'gift-cards',
                  name: 'giftCards',
                  builder: (_, _) => const GiftCardsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/event/:id',
      name: 'eventDetail',
      pageBuilder: (_, s) =>
          _detailPage(s, EventDetailScreen(eventId: s.pathParameters['id']!)),
      routes: [
        GoRoute(
          path: 'book',
          name: 'booking',
          pageBuilder: (_, s) => _detailPage(
            s,
            BookingConfirmationScreen(eventId: s.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, _) => const AuthScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (_, _) => const AuthScreen(register: true),
    ),
  ],
);

class EventApp extends StatelessWidget {
  const EventApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'event. — Discover the extraordinary',
    debugShowCheckedModeBanner: false,
    routerConfig: appRouter,
    locale: const Locale('en', 'GB'),
    supportedLocales: const [Locale('en', 'GB')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => Directionality(
      textDirection: TextDirection.ltr,
      child: SessionCoordinator(
        onAuthChanged: _routerRefresh.notifyListeners,
        child: child!,
      ),
    ),
    theme: AppTheme.dark,
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'event',
          style: TextStyle(color: Colors.white),
        ),
        TextSpan(
          text: '.',
          style: TextStyle(color: gold),
        ),
      ],
    ),
    style: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -.7,
    ),
  );
}

const _labels = ['For you', 'Search', 'Discover', 'Tickets', 'Profile'];
const _icons = [
  Icons.home_outlined,
  Icons.search,
  Icons.explore_outlined,
  Icons.confirmation_number_outlined,
  Icons.person_outline,
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  void _go(int i) => navigationShell.goBranch(
    i,
    initialLocation: i == navigationShell.currentIndex,
  );
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width > 800;
    final selected = navigationShell.currentIndex;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(desktop ? 72 : 64),
        child: SafeArea(
          child: Container(
            height: desktop ? 72 : 64,
            decoration: const BoxDecoration(
              color: AppColors.backgroundDarker,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop && width < 1100
                        ? 24
                        : AppDimensions.pagePadding(width),
                  ),
                  child: Row(
                    children: [
                      InkWell(onTap: () => _go(0), child: const Brand()),
                      if (desktop) ...[
                        const Spacer(),
                        ...List.generate(
                          4,
                          (i) => Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width < 1100 ? 3 : 10,
                            ),
                            child: InkWell(
                              onTap: () => _go(i),
                              child: Container(
                                height: 72,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: selected == i
                                          ? gold
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _icons[i],
                                      size: 18,
                                      color: selected == i
                                          ? gold
                                          : AppColors.navInactive,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _labels[i],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: selected == i ? gold : muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: () => showCitySelector(context, ref),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: gold,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ref.watch(cityProvider),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Profile',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          side: const BorderSide(color: border),
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: () => _go(4),
                        icon: const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: desktop && selected == 4
          ? AccountFrame(
              path: GoRouterState.of(context).uri.path,
              child: navigationShell,
            )
          : navigationShell,
      bottomNavigationBar: desktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.navBarBg,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 72,
                  child: Row(
                    children: List.generate(
                      5,
                      (i) => Expanded(
                        child: Semantics(
                          selected: selected == i,
                          button: true,
                          child: InkWell(
                            onTap: () => _go(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: selected == i ? 1.05 : 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: TweenAnimationBuilder<Color?>(
                                    tween: ColorTween(
                                      end: selected == i
                                          ? gold
                                          : AppColors.navInactive,
                                    ),
                                    duration: const Duration(milliseconds: 200),
                                    builder: (_, color, _) =>
                                        Icon(_icons[i], color: color, size: 24),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _labels[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected == i
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected == i
                                        ? gold
                                        : AppColors.navInactive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
