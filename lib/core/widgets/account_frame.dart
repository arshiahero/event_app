import '../shared.dart';
import '../../features/extras.dart';

class AccountFrame extends ConsumerWidget {
  const AccountFrame({super.key, required this.child, required this.path});

  final Widget child;
  final String path;

  bool _active(String destination) {
    if (path == '/profile') return destination == '/profile/preferences';
    return path == destination || path.startsWith('$destination/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 800) return child;

    final sidebarWidth = width > 1100 ? 350.0 : 220.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: bg,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: AppDimensions.pagePadding(width),
                  ),
                  child: Container(
                    width: sidebarWidth,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 32, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: gold),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: gold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ref.watch(demoDisplayNameProvider),
                                      style: AppTypography.cardTitle.copyWith(
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'So many good things ahead.',
                                      style: AppTypography.body,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 20),
                          _AccountMenuItem(
                            icon: Icons.place_outlined,
                            label: ref.watch(cityProvider),
                            onTap: () => showCitySelector(context, ref),
                          ),
                          for (final item in const <(IconData, String, String)>[
                            (
                              Icons.favorite_border,
                              'My favourites',
                              '/profile/favourites',
                            ),
                            (
                              Icons.confirmation_number_outlined,
                              'My tickets',
                              '/tickets',
                            ),
                            (
                              Icons.workspace_premium_outlined,
                              'event Club & rewards',
                              '/profile/club',
                            ),
                            (
                              Icons.card_giftcard,
                              'Gift cards',
                              '/profile/gift-cards',
                            ),
                            (
                              Icons.tune,
                              'My preferences',
                              '/profile/preferences',
                            ),
                            (
                              Icons.help_outline,
                              'Help & support',
                              '/profile/help',
                            ),
                          ])
                            _AccountMenuItem(
                              icon: item.$1,
                              label: item.$2,
                              active: _active(item.$3),
                              onTap: () => context.go(item.$3),
                            ),
                          const SizedBox(height: 24),
                          const AccountSessionActions(),
                          const SizedBox(height: 16),
                          const Text(
                            'Your demo corner. Saved only during this visit.',
                            style: AppTypography.small,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: ContentInsets(horizontal: 24, child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.primarySurface,
          focusColor: AppColors.primarySurface,
          splashColor: gold.withValues(alpha: .12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: active ? gold : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: active ? gold : Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle.copyWith(
                      color: active ? gold : Colors.white,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
