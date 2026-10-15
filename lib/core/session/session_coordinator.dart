import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../shared.dart';
import '../network/infrastructure_providers.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/catalog.dart';

final transportAvailableProvider = StateProvider<bool>((ref) => true);
final preferenceNoticeProvider = StateProvider<String?>((ref) => null);

/// Hydrates non-sensitive preferences and coordinates writes in their original order.
class SessionCoordinator extends ConsumerStatefulWidget {
  const SessionCoordinator({
    super.key,
    required this.child,
    required this.onAuthChanged,
  });
  final Widget child;
  final VoidCallback onAuthChanged;
  @override
  ConsumerState<SessionCoordinator> createState() => _SessionCoordinatorState();
}

class _SessionCoordinatorState extends ConsumerState<SessionCoordinator> {
  bool restoring = true;
  bool applyingRestore = false;
  bool dirty = false;
  bool saving = false;
  StreamSubscription<List<ConnectivityResult>>? connection;

  @override
  void initState() {
    super.initState();
    // ۱. گوش دادن به تغییرات تمام پروایدرها (شامل علاقه‌مندی‌ها و بلیت‌ها)
    ref.listenManual(cityProvider, (_, _) => _changed());
    ref.listenManual(interestsProvider, (_, _) => _changed());
    ref.listenManual(emailProvider, (_, _) => _changed());
    ref.listenManual(remindersProvider, (_, _) => _changed());
    ref.listenManual(favoritesProvider, (_, _) => _changed());
    ref.listenManual(ticketsProvider, (_, _) => _changed());

    ref.listenManual(authProvider, (_, state) {
      state.whenData((user) {
        if (mounted)
          ref.read(demoDisplayNameProvider.notifier).state =
              user?.name ?? 'Experience seeker';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthChanged();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  void _changed() {
    if (applyingRestore) return;
    dirty = true;
    if (!restoring) unawaited(_flush());
  }

  Future<void> _initialize() async {
    try {
      final storage = ref.read(localStorageProvider);
      // ۲. ابتدا تمام داده‌های ذخیره‌شده را از حافظه می‌خوانیم
      final city = await storage.getSelectedCity();
      final prefs = await storage.getPreferences();
      final savedFavs = await storage.getFavorites();
      final savedTickets = await storage.getTickets();

      if (!mounted) return;
      // ۳. اگر کاربر در حین لود شدن تغییری نداده بود، مقادیر را در Providerها قرار می‌دهیم
      if (!dirty) {
        applyingRestore = true;
        try {
          if (city != null && cities.any((entry) => entry.name == city))
            ref.read(cityProvider.notifier).state = city;
          if (prefs != null) {
            if (prefs['interests'] is List)
              ref
                  .read(interestsProvider.notifier)
                  .state = (prefs['interests'] as List)
                  .whereType<String>()
                  .where(
                    (value) => value != 'All' && categories.contains(value),
                  )
                  .toSet();
            if (prefs['emailNotifications'] is bool)
              ref.read(emailProvider.notifier).state =
                  prefs['emailNotifications'] as bool;
            if (prefs['experienceReminders'] is bool)
              ref.read(remindersProvider.notifier).state =
                  prefs['experienceReminders'] as bool;
          }
          if (savedFavs != null) {
            ref.read(favoritesProvider.notifier).state = savedFavs.toSet();
          }
          if (savedTickets != null) {
            ref.read(ticketsProvider.notifier).state = savedTickets
                .map(Reservation.fromJson)
                .toList();
          }
        } finally {
          applyingRestore = false;
        }
      }
    } catch (_) {
      if (mounted)
        ref.read(preferenceNoticeProvider.notifier).state =
            'Saved preferences could not be restored. Your changes will stay in this visit.';
    } finally {
      restoring = false;
      if (mounted && dirty) unawaited(_flush());
    }
    if (!mounted) return;
    final service = ref.read(connectivityServiceProvider);
    connection = service.changes.listen(
      (statuses) {
        if (mounted)
          ref.read(transportAvailableProvider.notifier).state = statuses.any(
            (value) => value != ConnectivityResult.none,
          );
      },
      onError: (Object error, StackTrace stack) {
        // A platform monitoring error is not evidence that the internet is offline.
      },
    );
    try {
      await service.start();
    } catch (_) {
      // Keep sample browsing available when a platform cannot report connectivity.
    }
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (!auth.isLoading && auth.asData?.value == null && !auth.hasError) {
      try {
        await ref.read(authProvider.notifier).restore();
      } catch (_) {}
    }
  }

  Future<void> _flush() async {
    if (saving || restoring || !mounted) return;
    saving = true;
    try {
      final storage = ref.read(localStorageProvider);
      while (mounted && dirty) {
        dirty = false;
        // ۴. خواندن آخرین وضعیت همه Providerها و ذخیره در حافظه محلی
        final city = ref.read(cityProvider);
        final preferences = <String, dynamic>{
          'interests': ref.read(interestsProvider).toList(),
          'emailNotifications': ref.read(emailProvider),
          'experienceReminders': ref.read(remindersProvider),
        };
        final favorites = ref.read(favoritesProvider).toList();
        final tickets = ref
            .read(ticketsProvider)
            .map((t) => t.toJson())
            .toList();
        try {
          await storage.saveSelectedCity(city);
          await storage.savePreferences(preferences);
          await storage.saveFavorites(favorites);
          await storage.saveTickets(tickets);
          if (mounted) ref.read(preferenceNoticeProvider.notifier).state = null;
        } catch (_) {
          if (mounted)
            ref.read(preferenceNoticeProvider.notifier).state =
                'Preferences could not be saved. They will stay in this visit.';
        }
      }
    } catch (_) {
      if (mounted)
        ref.read(preferenceNoticeProvider.notifier).state =
            'Preference storage is unavailable. Your changes are still active for this visit.';
    } finally {
      saving = false;
    }
  }

  Future<void> _cancelConnection() async {
    try {
      await connection?.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_cancelConnection());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(transportAvailableProvider);
    final notice = ref.watch(preferenceNoticeProvider);
    return Column(
      children: [
        if (!online || notice != null)
          Material(
            color: surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      online ? Icons.info_outline : Icons.wifi_off,
                      color: gold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notice ??
                            'No connection detected. Sample experiences remain available.',
                        style: AppTypography.small,
                      ),
                    ),
                    if (notice != null)
                      IconButton(
                        tooltip: 'Dismiss notice',
                        onPressed: () =>
                            ref.read(preferenceNoticeProvider.notifier).state =
                                null,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
