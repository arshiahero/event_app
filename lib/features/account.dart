import 'dart:async';

import '../core/shared.dart';
import '../data/catalog.dart';
import 'extras.dart';
import '../core/router/route_access.dart';
import 'auth/auth_provider.dart';
import 'auth/auth_models.dart';
import '../core/config/app_config.dart';

const _demoNotice =
    'ⓘ Sample reservations are saved only during this visit. No real tickets or payments are issued.';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});
  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  bool past = false;

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    final now = DateTime.now();
    final upcoming = tickets
        .where((ticket) => !ticket.startsAt.isBefore(now))
        .length;
    final filtered = tickets
        .where((ticket) => ticket.startsAt.isBefore(now) == past)
        .toList();
    return _Page(
      title: 'Your tickets',
      subtitle: 'Good times ahead. Keep them close.',
      onRefresh: () async {
        // Refresh the date partition, not the session's reservation provider.
        if (mounted) setState(() {});
      },
      children: [
        Row(
          children: [
            for (final value in [false, true])
              Expanded(
                child: Semantics(
                  selected: past == value,
                  button: true,
                  child: InkWell(
                    onTap: () => setState(() => past = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: past == value ? gold : AppColors.divider,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            value ? 'Past' : 'Upcoming',
                            style: TextStyle(
                              color: past == value ? gold : muted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                            ),
                            child: FittedBox(
                              child: Text(
                                '${value ? tickets.length - upcoming : upcoming}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.confirmation_number_outlined,
            title: past
                ? 'No past reservations yet'
                : 'Find your next good plan',
            message: 'Choose an experience to save a sample reservation here.',
            actionLabel: 'Discover experiences →',
            onAction: () => context.go('/'),
          ),
        for (var index = 0; index < filtered.length; index++)
          _StaggeredCard(
            key: ValueKey('${past}_${filtered[index].id}'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _TicketCard(ticket: filtered[index]),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          _demoNotice,
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
        ),
      ],
    );
  }
}

class _StaggeredCard extends StatefulWidget {
  const _StaggeredCard({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard> {
  Timer? _timer;
  bool _visible = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _timer?.cancel();
      _visible = true;
    } else if (!_visible && _timer == null) {
      _timer = Timer(Duration(milliseconds: widget.index * 100), () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final visible = _visible || reducedMotion;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, .05),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
        child: widget.child,
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final Reservation ticket;
  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 801;
    final details = Padding(
      padding: EdgeInsets.all(desktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SAMPLE RESERVATION',
            style: TextStyle(color: gold, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          Text(
            ticket.event.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _IconText(
                Icons.calendar_today_outlined,
                '${isoDate(ticket.date)} · ${ticket.time}',
              ),
              _IconText(Icons.place_outlined, ticket.event.venue),
            ],
          ),
          const Divider(height: 32, color: AppColors.divider),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                '${ticket.quantity} tickets · ${ticket.type}',
                style: const TextStyle(color: muted, fontSize: 14),
              ),
              TextButton(
                onPressed: () => context.push('/tickets/${ticket.id}'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                ),
                child: const Text(
                  'View reservation >',
                  style: TextStyle(color: gold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Material(
      color: surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
      // در انتهای متد build کلاس _TicketCard، بخش child ویجت Material را به این شکل تغییر دهید:
      child: desktop
          ? Row(
              children: [
                EventImage(ticket.event.image, height: 180, width: 160),
                Expanded(child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EventImage(
                  ticket.event.image,
                  height: 180,
                  width: double.infinity,
                ),
                details,
              ],
            ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: muted),
      const SizedBox(width: 6),
      Flexible(
        child: Text(text, style: const TextStyle(color: muted, fontSize: 14)),
      ),
    ],
  );
}

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final String ticketId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Reservation? ticket;
    for (final item in ref.watch(ticketsProvider)) {
      if (item.id == ticketId) {
        ticket = item;
        break;
      }
    }
    if (ticket == null) {
      return PopScope(
        canPop: context.canPop(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) context.go('/tickets');
        },
        child: Dialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Close reservation',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/tickets');
                        }
                      },
                    ),
                  ),
                  EmptyState(
                    title: 'Reservation not found',
                    message:
                        'Sample reservations are saved only during this visit.',
                    actionLabel: 'My tickets →',
                    onAction: () => context.go('/tickets'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final reservation = ticket;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/tickets');
      },
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Material(
                color: AppColors.surfaceElevated,
                elevation: 12,
                shadowColor: AppColors.shadowColor,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        EventImage(
                          reservation.event.image,
                          height: 200,
                          width: double.infinity,
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            tooltip: 'Close reservation',
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: const EdgeInsets.all(4),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/tickets');
                              }
                            },
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.overlay,
                                shape: BoxShape.circle,
                                border: Border.all(color: border),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            reservation.event.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'SAMPLE RESERVATION',
                            style: TextStyle(
                              color: gold,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final row in <(String, String)>[
                            ('Reference', reservation.id),
                            ('Date', isoDate(reservation.date)),
                            ('Time', reservation.time),
                            ('Venue', reservation.event.venue),
                            (
                              'Tickets',
                              '${reservation.quantity} × ${reservation.type}',
                            ),
                            ('Sample total', currency(reservation.total)),
                          ])
                            Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.divider),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    row.$1,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      row.$2,
                                      textAlign: TextAlign.right,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: row.$1 == 'Sample total'
                                            ? gold
                                            : Colors.white,
                                        fontWeight: row.$1 == 'Sample total'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            _demoNotice,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () => context.push('/profile/help'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: border),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Need a hand? →'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _Page(
    title: 'Your little corner of event',
    titleSize: 24,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.sizeOf(context).width > 800) {
            return const _PreferencesContent();
          }
          const desktop = false;
          final menu = Column(
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
                    child: const Icon(Icons.person_outline, color: gold),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.watch(demoDisplayNameProvider),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'So many good things ahead.',
                          style: TextStyle(color: muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              _Menu(
                Icons.place_outlined,
                ref.watch(cityProvider),
                () => showCitySelector(context, ref),
                desktop: desktop,
              ),
              _Menu(
                Icons.favorite_border,
                'My favourites',
                () => context.push('/profile/favourites'),
                desktop: desktop,
              ),
              _Menu(
                Icons.confirmation_number_outlined,
                'My tickets',
                () => context.push('/tickets'),
                desktop: desktop,
              ),
              _Menu(
                Icons.workspace_premium_outlined,
                'event Club & rewards',
                () => context.push('/profile/club'),
                desktop: desktop,
              ),
              _Menu(
                Icons.card_giftcard,
                'Gift cards',
                () => context.push('/profile/gift-cards'),
                desktop: desktop,
              ),
              _Menu(
                Icons.tune,
                'My preferences',
                () => context.push('/profile/preferences'),
                desktop: desktop,
                selected: desktop,
              ),
              _Menu(
                Icons.help_outline,
                'Help & support',
                () => context.push('/profile/help'),
                desktop: desktop,
              ),
            ],
          );
          return menu;
        },
      ),
      const SizedBox(height: 24),
      if (MediaQuery.sizeOf(context).width <= 800)
        const AccountSessionActions(),
      const SizedBox(height: 16),
      const MockVisitReceipts(),
      const SizedBox(height: 16),
      const Text(
        'Demo profile: preferences and favourites are saved only during this visit.',
        style: TextStyle(color: muted),
      ),
    ],
  );
}

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _Page(children: [_PreferencesContent()]);
}

class _PreferencesContent extends ConsumerWidget {
  const _PreferencesContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(interestsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: gold, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'A little more you',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "The things you love. The experiences you'll love next.",
          style: TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 32),
        const Text(
          'Your interests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // درون _PreferencesContent، بخش Wrap مربوط به علاقه‌مندی‌ها را با این کد جایگزین کنید:
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final category in [
              'Live Music',
              'Culture',
              'Family',
              'Wellness',
              'Food & Drink',
            ])
              Builder(
                builder: (context) {
                  final isSelected = interests.contains(category);
                  return Semantics(
                    selected: isSelected,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        final next = {...interests};
                        if (!next.add(category)) next.remove(category);
                        ref.read(interestsProvider.notifier).state = next;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? gold : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? gold : AppColors.chipBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.onPrimary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 14,
                              ),
                              child: Text(category),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 32),
        const Row(
          children: [
            Icon(Icons.notifications_none, color: gold, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Stay in the loop',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: gold,
          checkColor: Colors.white,
          side: const BorderSide(color: border),
          title: const Text('Good plans in your inbox'),
          subtitle: const Text(
            'Fresh finds and handpicked experiences.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          value: ref.watch(emailProvider),
          onChanged: (value) =>
              ref.read(emailProvider.notifier).state = value ?? false,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: gold,
          checkColor: Colors.white,
          side: const BorderSide(color: border),
          title: const Text('Experience reminders'),
          subtitle: const Text(
            'A heads-up before your next good plan.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          value: ref.watch(remindersProvider),
          onChanged: (value) =>
              ref.read(remindersProvider.notifier).state = value ?? false,
        ),
        const SizedBox(height: 20),
        const Text(
          'Settings are saved only during this visit. No real emails or notifications are sent.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
      ],
    );
  }
}

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return _Page(
      title: 'My favourites',
      subtitle: 'Experiences saved for later.',
      children: [
        CatalogContent(
          builder: (catalog) {
            final selected = catalog
                .where((event) => favorites.contains(event.id))
                .toList();
            return selected.isEmpty
                ? EmptyState(
                    icon: Icons.favorite_border,
                    title: 'No saved experiences yet',
                    message: 'Tap the heart on an experience to keep it here.',
                    actionLabel: 'Discover experiences →',
                    onAction: () => context.go('/'),
                  )
                : EventGrid(selected);
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Favourites are saved only during this visit.',
          style: TextStyle(color: muted),
        ),
      ],
    );
  }
}

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _Page(
    title: 'Help & support',
    children: [
      const Text(
        'This is a demo. Authentication uses a mock identity and local mock tokens, not a real account. Payments, ticket issuance, emails and live support are not connected.',
        style: TextStyle(color: muted, height: 1.6),
      ),
      const SizedBox(height: 24),
      DemoColumns(
        left: DemoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: gold,
                size: 32,
              ),
              const SizedBox(height: 16),
              const SectionHeading(
                'Your good plans',
                subtitle:
                    'Find your session reservations and their selected details.',
              ),
              DemoPillButton(
                label: 'My tickets →',
                onPressed: () => context.go('/tickets'),
              ),
            ],
          ),
        ),
        right: DemoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.chat_bubble_outline, color: gold, size: 32),
              const SizedBox(height: 16),
              const SectionHeading(
                'Need a hand?',
                subtitle:
                    'Explore a mock support request. Nothing is actually sent.',
              ),
              DemoPillButton(
                label: 'Contact support · demo →',
                onPressed: () => context.push('/profile/help/contact'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),
      const MockVisitReceipts(),
      const SizedBox(height: 24),
      const SectionHeading('A few helpful answers'),
      for (final faq in const [
        (
          'How do I make a sample reservation?',
          'Choose an experience, date, time, ticket type and quantity, then confirm your sample reservation. No payment is taken.',
        ),
        (
          'Where are my reservations?',
          'My tickets shows reservations from this visit. Closing or reloading the app may clear session data.',
        ),
        (
          'Can I use this ticket for entry?',
          'No. References and reservation details are samples only. No real ticket or booking is issued.',
        ),
        (
          'Can I change or cancel a purchase?',
          'Real purchases are not connected. For real events, check the official seller and organiser’s terms.',
        ),
        (
          'How can I contact support?',
          'The contact form saves a local mock receipt for this visit. No real case is created, no messages are sent and no reply will arrive.',
        ),
      ])
        ExpansionTile(
          title: Text(faq.$1),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq.$2,
                style: const TextStyle(color: muted, height: 1.6),
              ),
            ),
          ],
        ),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: () => context.go('/tickets'),
        child: const Text('My tickets →'),
      ),
    ],
  );
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.register = false});
  final bool register;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  String? _validate(String? value, void Function(String) validate) {
    try {
      validate(value ?? '');
      return null;
    } on AuthException catch (error) {
      return error.message;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted || _busy || ref.read(authProvider).isLoading) return;
    setState(() => _error = null);
    final returnLocation =
        appAuthGuard.safeReturnLocation(
          GoRouterState.of(context).uri.queryParameters['returnTo'],
        ) ??
        '/profile';
    if (!(_form.currentState?.validate() ?? false)) {
      _password.clear();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      if (!ref.read(appConfigProvider).useMocks) {
        throw const AuthException(
          'Only mock authentication is available on this screen.',
        );
      }
      final controller = ref.read(authProvider.notifier);
      if (widget.register) {
        await controller.register(_name.text, _email.text, _password.text);
      } else {
        await controller.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      final user = ref.read(authProvider).asData?.value;
      if (user == null) {
        throw const AuthException(
          'Mock sign-in was not confirmed. Please retry.',
        );
      }
      ref.read(demoDisplayNameProvider.notifier).state = user.name;
      _password.clear();
      context.go(returnLocation);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is AuthException
              ? error.message
              : 'Could not complete mock authentication. Please retry.',
        );
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    children: [
      DemoColumns(
        left: DemoHero(
          label: 'DISCOVER THE EXTRAORDINARY',
          title: 'Your next great story starts here.',
          subtitle:
              'One city. So many possibilities. Find a little more of what moves you.',
          height: MediaQuery.sizeOf(context).width > 800 ? 600 : 380,
        ),
        right: DemoPanel(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('GOOD PLANS START HERE', style: AppTypography.label),
                const SizedBox(height: 20),
                SectionHeading(
                  widget.register ? 'Make yourself at home' : 'Welcome back',
                  subtitle: widget.register
                      ? 'Explore a sample sign-up experience.'
                      : 'Your little corner of event awaits.',
                ),
                const Text(
                  'MOCK ONLY · Use fictional details and a made-up password. Nothing is transmitted. A mock identity and local mock tokens are created, not a real account.',
                  style: AppTypography.small,
                ),
                const SizedBox(height: 24),
                if (widget.register)
                  DemoField(
                    controller: _name,
                    label: 'Name',
                    enabled: !_busy && !ref.watch(authProvider).isLoading,
                    validator: (value) => _validate(value, AuthValidation.name),
                  ),
                DemoField(
                  controller: _email,
                  enabled: !_busy && !ref.watch(authProvider).isLoading,
                  label: 'Email',
                  validator: demoEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                DemoField(
                  controller: _password,
                  label: 'Password (8+ made-up characters)',
                  enabled: !_busy && !ref.watch(authProvider).isLoading,
                  obscure: _obscure,
                  validator: (value) =>
                      _validate(value, AuthValidation.password),
                  suffix: IconButton(
                    tooltip: _obscure
                        ? 'Show demo password'
                        : 'Hide demo password',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: gold)),
                  ),
                DemoPillButton(
                  loading: _busy || ref.watch(authProvider).isLoading,
                  label: widget.register
                      ? 'Create demo profile →'
                      : 'Enter demo profile →',
                  onPressed: _busy || ref.watch(authProvider).isLoading
                      ? null
                      : _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _busy || ref.watch(authProvider).isLoading
                      ? null
                      : () {
                          _password.clear();
                          final returnTo = appAuthGuard.safeReturnLocation(
                            GoRouterState.of(
                              context,
                            ).uri.queryParameters['returnTo'],
                          );
                          context.go(
                            Uri(
                              path: widget.register ? '/login' : '/register',
                              queryParameters: returnTo == null
                                  ? null
                                  : {'returnTo': returnTo},
                            ).toString(),
                          );
                        },
                  child: Text(
                    widget.register
                        ? 'Already exploring? Demo sign in →'
                        : 'New here? Demo sign up →',
                  ),
                ),
                TextButton(
                  onPressed: _busy || ref.watch(authProvider).isLoading
                      ? null
                      : () {
                          _password.clear();
                          context.go('/');
                        },
                  child: const Text('Continue discovering →'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mock identity and tokens live only in local memory for this visit. Passwords are cleared after each attempt and never saved.',
                  style: AppTypography.small,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page({
    this.title = '',
    this.subtitle = '',
    this.titleSize = 28,
    required this.children,
    this.onRefresh,
  });
  final String title, subtitle;
  final double titleSize;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      color: bg,
      child: SafeArea(
        child: PageContent(
          onRefresh: onRefresh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title.isNotEmpty) ...[
                const Text('GOOD PLANS START HERE', style: AppTypography.label),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
              ],
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class _Menu extends StatelessWidget {
  const _Menu(
    this.icon,
    this.label,
    this.onTap, {
    this.selected = false,
    this.desktop = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected, desktop;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: desktop
          ? (selected ? AppColors.primarySurface : Colors.transparent)
          : surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(desktop ? 0 : 12),
        side: desktop
            ? BorderSide.none
            : BorderSide(
                color: selected ? gold : border,
                width: selected ? 1.5 : 1,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: desktop && selected
              ? const BoxDecoration(
                  border: Border(left: BorderSide(color: gold, width: 3)),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, color: gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: selected ? gold : Colors.white,
                  ),
                ),
              ),
              if (!desktop)
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    ),
  );
}
