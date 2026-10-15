import 'dart:async';

import '../core/shared.dart';
import '../data/catalog.dart';
import '../core/widgets/mock_venue_map.dart';
import '../core/widgets/parallax_image.dart';
import '../core/widgets/paginated_collection.dart';

List<Event> _filtered(List<Event> catalog, WidgetRef ref, {String query = ''}) {
  final city = ref.watch(cityProvider);
  final category = ref.watch(categoryProvider);
  final maxPrice = ref.watch(maxPriceProvider);
  // The sample catalog has no dated inventory: every sample is available on all dates.
  return catalog
      .where(
        (event) =>
            event.city == city &&
            (category == 'All' || event.category == category) &&
            event.price <= maxPrice &&
            matchesEventQuery(event, query),
      )
      .toList();
}

void _reset(WidgetRef ref) {
  ref.read(categoryProvider.notifier).state = 'All';
  ref.read(maxPriceProvider.notifier).state = 300;
  ref.read(filterDateProvider.notifier).state = null;
}

Future<void> _refresh(WidgetRef ref) async {
  ref.invalidate(catalogProvider);
  await ref.read(catalogProvider.future);
}

void _search(BuildContext context, String query) =>
    context.go('/search/results?q=${Uri.encodeQueryComponent(query.trim())}');
void _detail(BuildContext context, Event event) =>
    context.push('/event/${Uri.encodeComponent(event.id)}');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(cityProvider);
    final width = MediaQuery.sizeOf(context).width;
    return _DiscoveryPage(
      ref: ref,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PageHeading(
            'GOOD PLANS START HERE',
            'Discover the extraordinary',
          ),
          if (width > 800)
            const Text(
              'Your city. Your people. Your next unforgettable moment.',
              style: AppTypography.body,
            ),
          const SizedBox(height: 24),
          SearchBox(onSubmitted: (query) => _search(context, query)),
          const SizedBox(height: 20),
          CategoryChips(
            selected: ref.watch(categoryProvider),
            onSelected: (value) =>
                ref.read(categoryProvider.notifier).state = value,
          ),
          const SizedBox(height: 24),
          CatalogContent(
            builder: (catalog) {
              final available = _filtered(catalog, ref);
              final featured = available.take(4).toList();
              final trending =
                  available
                      .where((event) => event.trendingRank != null)
                      .toList()
                    ..sort(
                      (a, b) => a.trendingRank!.compareTo(b.trendingRank!),
                    );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (featured.isEmpty)
                    EmptyState(onAction: () => _reset(ref))
                  else
                    _HeroCarousel(events: featured),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _TrustBadge(
                        Icons.verified_outlined,
                        'Handpicked experiences',
                      ),
                      _TrustBadge(Icons.star_outline, 'Loved by millions'),
                      _TrustBadge(
                        Icons.confirmation_number_outlined,
                        'A world of good plans',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SectionHeading(
                    'Trending in $city',
                    label: "THE CITY'S FAVOURITES",
                    subtitle: "The experiences everyone's talking about",
                    action: () => context.push('/discover'),
                  ),
                  if (trending.isEmpty)
                    EmptyState(onAction: () => _reset(ref))
                  else
                    HeroMode(
                      enabled: false,
                      child: width <= 450
                          ? _EventRail(trending, ranked: true)
                          : _RankedGrid(trending.take(4).toList()),
                    ),
                  const SizedBox(height: 40),
                  SectionHeading(
                    'A little inspiration goes a long way',
                    label: 'MAKE IT A MOMENT',
                    actionLabel: 'Find your thing →',
                    action: () => context.push('/discover'),
                  ),
                  const _InspirationGallery(),
                  const SizedBox(height: 40),
                  const SectionHeading(
                    'More good things ahead',
                    label: 'WORTH MAKING TIME FOR',
                    subtitle:
                        'Something new, something unexpected, something you.',
                  ),
                  if (available.isEmpty)
                    EmptyState(onAction: () => _reset(ref))
                  else
                    PaginatedCollection(
                      items: available,
                      builder: (page) => EventGrid(page),
                    ),
                  const SizedBox(height: 48),
                  _HomeFooterSection(city: city),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late String _query;
  String? _routeQuery;
  Timer? _debounce;
  bool _map = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: _query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query =
        GoRouterState.of(context).uri.queryParameters['q'] ??
        widget.initialQuery;
    if (_routeQuery != query) {
      _routeQuery = query;
      _setQuery(query, rebuild: false);
    }
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      _setQuery(widget.initialQuery, rebuild: false);
    }
  }

  void _setQuery(String value, {bool rebuild = true}) {
    _debounce?.cancel();
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    if (rebuild) {
      setState(() => _query = value);
    } else {
      _query = value;
    }
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clear() {
    _reset(ref);
    _setQuery('');
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters.containsKey('q')) context.go('/search');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(cityProvider);
    final date = ref.watch(filterDateProvider);
    final filtered =
        _query.trim().isNotEmpty ||
        ref.watch(categoryProvider) != 'All' ||
        ref.watch(maxPriceProvider) < 300 ||
        date != null;
    return _DiscoveryPage(
      ref: ref,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeading('FIND YOUR THING IN ${city.toUpperCase()}', 'Search'),
          const SizedBox(height: 24),
          SearchBox(
            controller: _controller,
            hint: 'Experiences, artists, venues...',
            onChanged: _changed,
            onSubmitted: _setQuery,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _ViewToggle(
              map: _map,
              onChanged: (value) => setState(() => _map = value),
            ),
          ),
          const SizedBox(height: 24),
          const _SmallHeading('Popular searches'),
          _PopularSearches(const [
            'Candlelight',
            'Immersive',
            'Rooftop',
            'Festival',
            'Garden',
            'Hans Zimmer',
          ], _setQuery),
          const SizedBox(height: 40),
          if (!filtered && !_map) ...[
            const _SmallHeading('Browse by mood'),
            _MoodGrid(onSelected: _setQuery),
          ] else
            CatalogContent(
              builder: (catalog) {
                final results = _filtered(catalog, ref, query: _query);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      '${_query.isEmpty ? 'Experiences' : _query} — ${results.length} experiences',
                      subtitle: date == null
                          ? ''
                          : '${dateLabel(date)} · Sample availability',
                      actionLabel: 'Clear all',
                      action: _clear,
                    ),
                    if (results.isEmpty)
                      EmptyState(
                        title: 'No matching experiences',
                        message:
                            'No sample experiences match this search in $city. Try another search, city or filter.',
                        onAction: _clear,
                        actionLabel: 'Clear all',
                      )
                    else if (_map)
                      _VenuePreview(results)
                    else
                      PaginatedCollection(
                        items: results,
                        builder: (page) => _ResultsList(page, date: date),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _sort = 'Recommended';

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(cityProvider);
    final date = ref.watch(filterDateProvider);
    final category = ref.watch(categoryProvider);
    return _DiscoveryPage(
      ref: ref,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeading('FIND YOUR KIND OF EXTRAORDINARY', 'Discover $city'),
          const Text(
            'Your next great story starts with a good plan.',
            style: AppTypography.body,
          ),
          const SizedBox(height: 24),
          SearchBox(
            hint: 'Search experiences in $city',
            onSubmitted: (value) => _search(context, value),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 3),
                  );
                  if (mounted && selected != null) {
                    ref.read(filterDateProvider.notifier).state = selected;
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(date == null ? 'Any date' : dateLabel(date)),
              ),
              OutlinedButton.icon(
                onPressed: () => showFilters(context, ref),
                icon: const Icon(Icons.tune, size: 16),
                label: Text(category == 'All' ? 'Category' : category),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.chipBorder),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.expand_more),
                  items:
                      [
                            'Recommended',
                            'Highest rated',
                            'Lowest price',
                            'Shortest duration',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                '↕ $value',
                                style: AppTypography.body,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SmallHeading('Popular searches'),
          _PopularSearches(const [
            'Candlelight',
            'Concerts',
            'Gardens',
            'Immersive',
            'Rooftop',
            'Coldplay',
          ], (value) => _search(context, value)),
          const SizedBox(height: 40),
          const SectionHeading('A world of possibilities'),
          const _DiscoverCategories(),
          const SizedBox(height: 40),
          CatalogContent(
            builder: (catalog) {
              final results = _filtered(catalog, ref);
              switch (_sort) {
                case 'Highest rated':
                  results.sort((a, b) => b.rating.compareTo(a.rating));
                  break;
                case 'Lowest price':
                  results.sort((a, b) => a.price.compareTo(b.price));
                  break;
                case 'Shortest duration':
                  results.sort((a, b) => a.duration.compareTo(b.duration));
                  break;
                default:
                  results.sort(
                    (a, b) => (a.trendingRank ?? 999).compareTo(
                      b.trendingRank ?? 999,
                    ),
                  );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.explore_outlined, color: gold),
                  ),
                  SectionHeading(
                    'Handpicked for you',
                    subtitle:
                        '${results.length} extraordinary experiences${date == null ? '' : ' · ${dateLabel(date)} · Sample availability'}',
                  ),
                  if (results.isEmpty)
                    EmptyState(onAction: () => _reset(ref))
                  else
                    _EventRail(results),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiscoveryPage extends StatelessWidget {
  const _DiscoveryPage({required this.ref, required this.child});
  final WidgetRef ref;
  final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: PageContent(onRefresh: () => _refresh(ref), child: child),
      ),
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading(this.label, this.title);
  final String label, title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.label),
      const SizedBox(height: 12),
      GoldPeriodTitle(
        title,
        size: MediaQuery.sizeOf(context).width > 800 ? 36 : 32,
      ),
      const SizedBox(height: 8),
    ],
  );
}

class _SmallHeading extends StatelessWidget {
  const _SmallHeading(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 20)),
  );
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.events});
  final List<Event> events;
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  bool _enabled = true;
  bool _interacting = false;

  bool get _visible {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    return top < MediaQuery.sizeOf(context).height && top + box.size.height > 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    _timer?.cancel();
    if (_enabled) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted ||
            !_enabled ||
            _interacting ||
            !_visible ||
            !_controller.hasClients ||
            widget.events.length < 2 ||
            _controller.position.isScrollingNotifier.value) {
          return;
        }
        _go(_page + 1);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.map((e) => e.id).join(',') !=
        widget.events.map((e) => e.id).join(',')) {
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  void _go(int index) {
    if (!_controller.hasClients || widget.events.isEmpty) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index % widget.events.length);
      return;
    }
    _controller.animateToPage(
      index % widget.events.length,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width <= 450
        ? 420.0
        : width <= 800
        ? 460.0
        : 500.0;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _interacting = true,
                onPointerUp: (_) => _interacting = false,
                onPointerCancel: (_) => _interacting = false,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.events.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) =>
                      _HeroEvent(widget.events[index]),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: width <= 450 ? 8 : 24,
              right: width <= 450 ? 8 : 24,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: width > 800
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < widget.events.length; i++)
                            Semantics(
                              label:
                                  'Slide ${i + 1} of ${widget.events.length}',
                              selected: i == _page,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => _go(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: i == _page ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == _page
                                          ? gold
                                          : AppColors.textSecondary,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _CarouselArrow(
                    tooltip: 'Previous experience',
                    icon: Icons.chevron_left,
                    onPressed: widget.events.length > 1
                        ? () => _go(_page - 1)
                        : null,
                  ),
                  _CarouselArrow(
                    tooltip: 'Next experience',
                    icon: Icons.chevron_right,
                    onPressed: widget.events.length > 1
                        ? () => _go(_page + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.overlayLight,
            border: Border.all(color: border),
          ),
          child: Icon(
            icon,
            size: 24,
            color: onPressed == null ? AppColors.textTertiary : Colors.white,
          ),
        ),
      ),
    ),
  );
}

class _HeroEvent extends StatelessWidget {
  const _HeroEvent(this.event);
  final Event event;
  @override
  Widget build(BuildContext context) {
    final candlelight = event.title.toLowerCase().contains('candlelight');
    final desktop = MediaQuery.sizeOf(context).width > 800;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ParallaxImage(event.image),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.imageOverlay),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlayLight,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .15),
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: gold, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'THE EVENT EDIT',
                        style: TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  candlelight
                      ? 'A little candlelight.\nAn unforgettable night.'
                      : event.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heroTitle.copyWith(
                    fontSize: desktop ? 32 : 28,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  candlelight
                      ? "Rediscover the music you love, in a setting you'll never forget."
                      : '${event.venue} · ${event.city}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  height: 44,
                  onPressed: () => _detail(context, event),
                  label: candlelight
                      ? 'Discover Candlelight →'
                      : 'Discover experience →',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: gold, size: 16),
      const SizedBox(width: 8),
      Flexible(
        child: Text(text, style: AppTypography.body.copyWith(fontSize: 12)),
      ),
    ],
  );
}

class _EventRail extends StatelessWidget {
  const _EventRail(this.events, {this.ranked = false});
  final List<Event> events;
  final bool ranked;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = MediaQuery.sizeOf(context).width <= 450;
      final width = mobile ? 260.0 : 280.0;
      return SizedBox(
        height: 400,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => SizedBox(
            width: width,
            child: RepaintBoundary(
              child: EventCard(
                events[index],
                rank: ranked ? events[index].trendingRank : null,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RankedGrid extends StatelessWidget {
  const _RankedGrid(this.events);
  final List<Event> events;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = MediaQuery.sizeOf(context).width <= 800 ? 2 : 4;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: events
            .map(
              (event) => SizedBox(
                width: (constraints.maxWidth - (count - 1) * 16) / count,
                child: EventCard(event, rank: event.trendingRank),
              ),
            )
            .toList(),
      );
    },
  );
}

const _inspirations = [
  ('LIVE MUSIC', 'Music that moves you', 'candlelight', 'Concerts'),
  (
    'PLANS WITH YOUR PEOPLE',
    'A little out of the ordinary',
    'garden',
    'Family Adventures',
  ),
  (
    'ART & IMMERSIVE EXPERIENCES',
    'Step into something new',
    'immersive',
    'Immersive',
  ),
];

class _InspirationGallery extends StatelessWidget {
  const _InspirationGallery();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = MediaQuery.sizeOf(context).width > 800;
      final height = desktop ? 300.0 : 280.0;
      Widget card(int i) {
        final item = _inspirations[i];
        return _ImageTile(
          image: item.$3,
          height: height,
          label: item.$1,
          title: item.$2,
          showArrow: true,
          onTap: () => _search(context, item.$4),
        );
      }

      if (desktop) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: card(i)),
            ],
          ],
        );
      }
      return SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, index) => const SizedBox(width: 16),
          itemBuilder: (context, i) =>
              SizedBox(width: constraints.maxWidth * .88, child: card(i)),
        ),
      );
    },
  );
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.map, required this.onChanged});
  final bool map;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final value in [false, true])
          Semantics(
            selected: map == value,
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onChanged(value),
                child: Center(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: map == value ? gold : Colors.transparent,
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.horizontal(
                        left: value ? Radius.zero : const Radius.circular(8),
                        right: value ? const Radius.circular(8) : Radius.zero,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          value ? Icons.map_outlined : Icons.view_list_outlined,
                          size: 16,
                          color: map == value
                              ? AppColors.onPrimary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          value ? 'Map' : 'List',
                          style: AppTypography.body.copyWith(
                            color: map == value
                                ? AppColors.onPrimary
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PopularSearchChip extends StatelessWidget {
  const _PopularSearchChip(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.chipBorder),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
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

class _PopularSearches extends StatelessWidget {
  const _PopularSearches(this.queries, this.onSelected);
  final List<String> queries;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: queries
        .map(
          (query) => _PopularSearchChip(query, onTap: () => onSelected(query)),
        )
        .toList(),
  );
}

const _moods = [
  ('Halloween', Icons.nightlight_round, 'garden', AppColors.moodHalloween),
  ('On a budget', Icons.savings_outlined, 'art', AppColors.moodBudget),
  (
    'Nightlife & party',
    Icons.celebration_outlined,
    'rooftop',
    AppColors.moodNightlife,
  ),
  (
    'Candlelight',
    Icons.music_note_outlined,
    'candlelight',
    AppColors.moodCandlelight,
  ),
  ('Romantic', Icons.favorite_border, 'food', AppColors.categoryCulture),
  (
    'Adventurous',
    Icons.landscape_outlined,
    'garden',
    AppColors.chipIconCulture,
  ),
  ('Relaxing', Icons.spa_outlined, 'wellness', AppColors.categoryWellness),
  ('Artistic', Icons.palette_outlined, 'art', AppColors.categoryFoodDrink),
];

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.onSelected});
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final count = viewport <= 450
        ? 2
        : viewport <= 800
        ? 3
        : 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _moods.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final mood = _moods[index];
        return _ImageTile(
          image: mood.$3,
          height: 200,
          title: mood.$1,
          icon: mood.$2,
          accent: mood.$4,
          onTap: () => onSelected(mood.$1),
        );
      },
    );
  }
}

class _ImageTile extends StatefulWidget {
  const _ImageTile({
    required this.image,
    required this.height,
    required this.title,
    required this.onTap,
    this.label = '',
    this.accent,
    this.icon,
    this.showArrow = false,
  });
  final IconData? icon;
  final bool showArrow;
  final String image, title, label;
  final double height;
  final Color? accent;
  final VoidCallback onTap;
  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AnimatedScale(
      scale: _hover ? 1.02 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(widget.accent == null ? 16 : 12),
          boxShadow: _hover ? AppShadows.elevatedShadow : AppShadows.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.accent == null ? 16 : 12),
          child: Material(
            color: surface,
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventImage(
                    'assets/images/${widget.image}.jpg',
                    height: widget.height,
                    width: double.infinity,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.imageOverlay,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: widget.accent == null
                          ? null
                          : AppColors.overlayLight,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.label.isNotEmpty)
                            Text(
                              widget.label,
                              style: AppTypography.category.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          if (widget.label.isNotEmpty)
                            const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.icon != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Icon(
                                    widget.icon,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: widget.accent == null ? 20 : 16,
                                  ),
                                ),
                              ),
                              if (widget.showArrow) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.accent != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 3, color: widget.accent),
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

class _ResultsList extends StatelessWidget {
  const _ResultsList(this.events, {this.date});
  final List<Event> events;
  final DateTime? date;
  @override
  Widget build(BuildContext context) => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: events.length,
    separatorBuilder: (_, index) => const SizedBox(height: 16),
    itemBuilder: (context, index) {
      final event = events[index];
      return Container(
        decoration: AppDecorations.card,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _detail(context, event),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: EventImage(event.image, width: 100, height: 100),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: AppTypography.cardTitle),
                        const SizedBox(height: 4),
                        Text('⌖ ${event.venue}', style: AppTypography.body),
                        Text(
                          date == null
                              ? 'All dates · Sample availability'
                              : '${dateLabel(date!)} · Sample availability',
                          style: AppTypography.small,
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              '★ ${event.rating}',
                              style: AppTypography.rating,
                            ),
                            Text(
                              'From ${currency(event.price)}',
                              style: AppTypography.priceSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _VenuePreview extends StatelessWidget {
  const _VenuePreview(this.events);
  final List<Event> events;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MockVenueMap(events: events),
      const SizedBox(height: 16),
      for (final event in events)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: border),
            ),
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined, color: gold),
              title: Text(event.venue),
              subtitle: Text('${event.title} · ${event.city}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _detail(context, event),
            ),
          ),
        ),
    ],
  );
}

const _discoverCategories = [
  ('Candlelight Concerts', 'candlelight'),
  ('Immersive Experiences', 'immersive'),
  ('Music Events', 'festival'),
  ('Family Adventures', 'garden'),
  ('Art & Culture', 'art'),
  ('Wellness & Mindfulness', 'wellness'),
  ('Food & Drink', 'food'),
  ('Plans for Two', 'rooftop'),
];

class _DiscoverCategories extends StatelessWidget {
  const _DiscoverCategories();
  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final count = viewport <= 450
        ? 2
        : viewport <= 800
        ? 3
        : 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _discoverCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisExtent: 56,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = _discoverCategories[index];
        return Semantics(
          button: true,
          label: category.$1,
          child: Container(
            decoration: AppDecorations.card,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _search(context, category.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: EventImage(
                          'assets/images/${category.$2}.jpg',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          category.$1,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            height: 1.1,
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
      },
    );
  }
}

class _HomeFooterSection extends StatelessWidget {
  const _HomeFooterSection({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(height: 1, color: AppColors.divider),
      const SizedBox(height: 40),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: const Icon(Icons.favorite_border, color: gold, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give a memory, not just a gift.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'A world of experiences. One thoughtful gift card.',
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      OutlinedButton(
        onPressed: () => context.push('/profile/gift-cards'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Explore gift cards  →'),
      ),
      const SizedBox(height: 40),
      const Divider(height: 1, color: AppColors.divider),
      const SizedBox(height: 32),
      const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'event ',
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
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Extraordinary experiences. Lasting memories.',
        style: AppTypography.body,
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          InkWell(
            onTap: () => context.push('/profile/help'),
            child: const Text('Help & support', style: AppTypography.body),
          ),
          InkWell(
            onTap: () => context.push('/profile/gift-cards'),
            child: const Text('Gift cards ↗', style: AppTypography.body),
          ),
          InkWell(
            onTap: () => context.push('/profile/favourites'),
            child: const Text('Your favourites ♡', style: AppTypography.body),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Divider(height: 1, color: AppColors.divider),
      const SizedBox(height: 20),
      const Text(
        '© 2026 event. Curated with love.',
        style: AppTypography.small,
      ),
      const SizedBox(height: 8),
      Text('$city, and a world of possibilities.', style: AppTypography.small),
    ],
  );
}
