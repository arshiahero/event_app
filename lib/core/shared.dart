import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'config/app_config.dart';
import '../data/catalog.dart';
import 'theme/app_theme.dart';
import '../features/events/domain/events_repository.dart';
import '../features/events/data/mock_events_repository.dart';
export 'package:flutter/material.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:go_router/go_router.dart';
export 'theme/app_theme.dart';
export '../features/events/domain/events_repository.dart';
export '../features/events/data/mock_events_repository.dart';

const bg = AppColors.background,
    surface = AppColors.surface,
    gold = AppColors.primary,
    muted = AppColors.textSecondary,
    border = AppColors.cardBorder;
final demoDisplayNameProvider = StateProvider<String>(
  (ref) => 'Experience seeker',
);
final cityProvider = StateProvider<String>((ref) => 'London');
final categoryProvider = StateProvider<String>((ref) => 'All');
final maxPriceProvider = StateProvider<double>((ref) => 300);
final favoritesProvider = StateProvider<Set<String>>((ref) => {});
final interestsProvider = StateProvider<Set<String>>((ref) => {'Live Music'});
final emailProvider = StateProvider<bool>((ref) => false);
final remindersProvider = StateProvider<bool>((ref) => true);
final ticketsProvider = StateProvider<List<Reservation>>(
  (ref) => [...mockTickets],
);
final filterDateProvider = StateProvider<DateTime?>((ref) => null);
final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => const MockEventsRepository(),
);
final catalogProvider = FutureProvider<List<Event>>(
  (ref) => ref.watch(eventsRepositoryProvider).getEvents(),
);
// اضافه کردن Providerهای اختصاصی برای نظرات و سوالات متداول هر رویداد
final eventReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, eventId) => ref.watch(eventsRepositoryProvider).getReviews(eventId),
);
final eventFaqsProvider = FutureProvider.family<List<Faq>, String>(
  (ref, eventId) => ref.watch(eventsRepositoryProvider).getFaqs(eventId),
);
String currency(num value) => NumberFormat.currency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 2,
).format(value);
String dateLabel(DateTime value) =>
    DateFormat('EEE d MMM', 'en_GB').format(value);
String isoDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
String shortDate(DateTime value) => DateFormat('MM/dd/yyyy').format(value);

class ContentInsets extends InheritedWidget {
  const ContentInsets({
    super.key,
    required this.horizontal,
    required super.child,
  });
  final double horizontal;
  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentInsets>()?.horizontal;
  @override
  bool updateShouldNotify(ContentInsets oldWidget) =>
      horizontal != oldWidget.horizontal;
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.child, this.onRefresh});
  final Widget child;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal =
        ContentInsets.of(context) ?? AppDimensions.pagePadding(width);
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 32, horizontal, 48),
            child: child,
          ),
        ),
      ),
    );
    return onRefresh == null
        ? scroll
        : RefreshIndicator(onRefresh: onRefresh!, color: gold, child: scroll);
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.label = '',
    this.subtitle = '',
    this.action,
    this.actionLabel = 'Explore all →',
  });
  final String title, label, subtitle, actionLabel;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label.toUpperCase(), style: AppTypography.label),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                fontSize: MediaQuery.sizeOf(context).width > 800 ? 30 : 26,
              ),
            );
            if (constraints.maxWidth < 400 && action != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  TextButton(
                    onPressed: action,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: heading),
                if (action != null)
                  TextButton(onPressed: action, child: Text(actionLabel)),
              ],
            );
          },
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.body),
        ],
      ],
    ),
  );
}

class GoldPeriodTitle extends StatelessWidget {
  const GoldPeriodTitle(this.text, {super.key, this.size = 32});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: text),
        const TextSpan(
          text: '.',
          style: TextStyle(color: gold),
        ),
      ],
    ),
    style: AppTypography.heroTitle.copyWith(fontSize: size),
  );
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.height = 180, this.width});
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: surface,
    highlightColor: AppColors.surfaceVariant,
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

class EventImage extends ConsumerWidget {
  const EventImage(this.path, {super.key, this.height, this.width});
  final String path;
  final double? height, width;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget fallback() => Semantics(
      label: 'Image placeholder',
      image: true,
      child: SizedBox(
        height: height ?? 180,
        width: width ?? double.infinity,
        child: const ColoredBox(color: AppColors.surfaceVariant),
      ),
    );
    if (!ref.watch(appConfigProvider).enableImages || path.isEmpty)
      return fallback();
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (_, url) =>
            LoadingSkeleton(height: height ?? 180, width: width),
        errorWidget: (_, url, error) => fallback(),
      );
    }
    return Image.asset(
      path,
      height: height,
      width: width,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, sync) => sync || frame != null
          ? child
          : LoadingSkeleton(height: height ?? 180, width: width),
      errorBuilder: (_, error, stack) => fallback(),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = 'A little more to discover',
    this.message = 'Try another search or change your filters.',
    this.onAction,
    this.actionLabel = 'Reset filters',
    this.icon = Icons.explore_outlined,
  });
  final String title, message, actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: gold),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.cardTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppTypography.body),
          if (onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    ),
  );
}

class CatalogContent extends ConsumerWidget {
  const CatalogContent({super.key, required this.builder});
  final Widget Function(List<Event>) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(catalogProvider)
      .when(
        data: builder,
        loading: () => const Column(
          children: [
            LoadingSkeleton(height: 52),
            SizedBox(height: 24),
            LoadingSkeleton(height: 420),
          ],
        ),
        error: (error, stack) => EmptyState(
          title: 'Something went off-plan',
          message: 'We couldn’t load these experiences. Please try again.',
          onAction: () => ref.invalidate(catalogProvider),
          actionLabel: 'Try again',
          icon: Icons.cloud_off_outlined,
        ),
      );
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.height = 52,
  });
  final VoidCallback? onPressed;
  final String label;
  final double height;
  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => pressed = true),
    onPointerUp: (_) => setState(() => pressed = false),
    onPointerCancel: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      scale: pressed ? .95 : 1,
      duration: const Duration(milliseconds: 100),
      child: SizedBox(
        height: widget.height,
        child: FilledButton(
          onPressed: widget.onPressed,
          child: Text(widget.label),
        ),
      ),
    ),
  );
}

class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton(this.eventId, {super.key});
  final String eventId;
  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.3,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.3,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 50,
    ),
  ]).animate(_animation);
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(favoritesProvider).contains(widget.eventId);
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        tooltip: saved ? 'Remove from favourites' : 'Save to favourites',
        style: IconButton.styleFrom(
          backgroundColor: bg.withValues(alpha: .65),
          minimumSize: const Size(44, 44),
        ),
        onPressed: () {
          final ids = {...ref.read(favoritesProvider)};
          saved ? ids.remove(widget.eventId) : ids.add(widget.eventId);
          ref.read(favoritesProvider.notifier).state = ids;
          _animation.forward(from: 0);
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(saved),
            color: saved ? AppColors.error : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  const EventCard(this.event, {super.key, this.rank});
  final Event event;
  final int? rank;
  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: AnimatedScale(
          scale: hover ? 1.02 : 1,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: hover
                  ? AppShadows.elevatedShadow
                  : AppShadows.cardShadow,
            ),
            child: Material(
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/event/${e.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: 'event-image-${e.id}',
                          child: EventImage(
                            e.image,
                            height: 180,
                            width: double.infinity,
                          ),
                        ),
                        if (widget.rank != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.trendingBadgeBg.withValues(
                                  alpha: .9,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.trendingNumber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      widget.rank!.toString().padLeft(2, '0'),
                                      style: const TextStyle(
                                        color: bg,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'TRENDING',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: FavoriteButton(e.id),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.category.toUpperCase(),
                            style: AppTypography.category.copyWith(
                              color: e.color,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 45,
                            child: Text(
                              e.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  e.venue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) =>
                                constraints.maxWidth < 190
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From ${currency(e.price)}',
                                        style: AppTypography.priceSmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '★ ${e.rating}',
                                        style: AppTypography.rating,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'From ${currency(e.price)}',
                                          style: AppTypography.priceSmall,
                                        ),
                                      ),
                                      Text(
                                        '★ ${e.rating}',
                                        style: AppTypography.rating,
                                      ),
                                    ],
                                  ),
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

class EventGrid extends StatelessWidget {
  const EventGrid(this.events, {super.key});
  final List<Event> events;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (events.isEmpty) return const EmptyState();
      final viewport = MediaQuery.sizeOf(context).width;
      final count = viewport <= 450
          ? 2
          : viewport <= 800
          ? 2
          : 4;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: events
            .map(
              (e) => SizedBox(
                width: (constraints.maxWidth - (count - 1) * 16) / count,
                child: EventCard(e),
              ),
            )
            .toList(),
      );
    },
  );
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.hint = 'Search experiences, artists, places...',
    this.controller,
  });
  final ValueChanged<String>? onChanged, onSubmitted;
  final String hint;
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) => SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textTertiary,
            size: 20,
          ),
          suffixIcon: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: border)),
            ),
            child: IconButton(
              tooltip: 'Filters',
              onPressed: () => showFilters(context, ref),
              icon: const Icon(
                Icons.tune,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _categoryIcons = [
  Icons.apps,
  Icons.music_note_outlined,
  Icons.favorite_border,
  Icons.eco_outlined,
  Icons.explore_outlined,
  Icons.restaurant_outlined,
];
const _categoryColors = [
  gold,
  AppColors.chipIconMusic,
  AppColors.chipIconFamily,
  AppColors.chipIconWellness,
  AppColors.chipIconCulture,
  AppColors.chipIconFood,
];

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(
        categories.length,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: AnimatedCategoryChip(
            label: categories[i],
            selected: selected == categories[i],
            icon: i == 0 ? null : _categoryIcons[i],
            iconColor: _categoryColors[i],
            onTap: () => onSelected(categories[i]),
          ),
        ),
      ),
    ),
  );
}

class AnimatedCategoryChip extends StatelessWidget {
  const AnimatedCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor = gold,
    this.outlined = false,
  });
  final String label;
  final bool selected, outlined;
  final VoidCallback onTap;
  final IconData? icon;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected && !outlined ? gold : Colors.transparent,
        border: Border.all(
          color: selected ? gold : AppColors.chipBorder,
          width: selected && outlined ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? outlined
                              ? gold
                              : AppColors.onPrimary
                        : Colors.white,
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

Future<void> showCitySelector(BuildContext context, WidgetRef ref) async {
  String query = '';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select your city',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'A new city. A world of possibilities.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: TextField(
                  onChanged: (v) => update(() => query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by city',
                    prefixIcon: const Icon(Icons.search),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: gold, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: cities
                        .where(
                          (c) => c.name.toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                        )
                        .map(
                          (c) => Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: gold,
                                  size: 20,
                                ),
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(c.country),
                                trailing: ref.read(cityProvider) == c.name
                                    ? const Icon(Icons.check, color: gold)
                                    : null,
                                onTap: () {
                                  ref.read(cityProvider.notifier).state =
                                      c.name;
                                  Navigator.pop(context);
                                },
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showFilters(BuildContext context, WidgetRef ref) async {
  var category = ref.read(categoryProvider);
  var price = ref.read(maxPriceProvider);
  var date = ref.read(filterDateProvider);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, color: gold),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Find your perfect plan',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Text(
                        "Just the experiences you're looking for.",
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: 32),
                      const Text('Date', style: AppTypography.cardTitle),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AnimatedCategoryChip(
                            label: 'Any date',
                            selected: date == null,
                            onTap: () => update(() => date = null),
                          ),
                          ...[
                            DateTime(2026, 10, 24),
                            DateTime(2026, 10, 25),
                          ].map(
                            (d) => AnimatedCategoryChip(
                              label: DateFormat('d MMM').format(d),
                              selected:
                                  date != null && DateUtils.isSameDay(date, d),
                              onTap: () => update(() => date = d),
                            ),
                          ),
                        ],
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            surface: AppColors.surfaceElevated,
                          ),
                        ),
                        child: CalendarDatePicker(
                          key: ValueKey(date),
                          initialDate: date ?? DateTime(2026, 10, 24),
                          firstDate: DateTime(2026),
                          lastDate: DateTime(2028, 12, 31),
                          onDateChanged: (d) => update(() => date = d),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Category', style: AppTypography.cardTitle),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: categories
                            .map(
                              (c) => AnimatedCategoryChip(
                                label: c,
                                selected: category == c,
                                onTap: () => update(() => category = c),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Maximum price',
                              style: AppTypography.cardTitle,
                            ),
                          ),
                          Text(
                            '£${price.round()}',
                            style: AppTypography.rating,
                          ),
                        ],
                      ),
                      Slider(
                        value: price,
                        min: 0,
                        max: 300,
                        divisions: 60,
                        onChanged: (v) => update(() => price = v),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('£0', style: AppTypography.small),
                          Text('£300', style: AppTypography.small),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: OutlinedButton(
                        onPressed: () => update(() {
                          category = 'All';
                          price = 300;
                          date = null;
                        }),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        height: 48,
                        onPressed: () {
                          ref.read(categoryProvider.notifier).state = category;
                          ref.read(maxPriceProvider.notifier).state = price;
                          ref.read(filterDateProvider.notifier).state = date;
                          Navigator.pop(context);
                        },
                        label: '✓ Apply filters',
                      ),
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
}
