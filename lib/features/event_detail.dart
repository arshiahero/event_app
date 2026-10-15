import 'dart:math' as math;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../core/shared.dart';
import 'booking/booking_repository.dart';
import '../data/catalog.dart';
import '../core/widgets/mock_venue_map.dart';

Event? _findEvent(String id) {
  for (final event in events) {
    if (event.id == id) return event;
  }
  return null;
}

String _countryForCity(String cityName) {
  for (final c in cities) {
    if (c.name == cityName) return c.country;
  }
  return 'United Kingdom';
}

const _disclaimer = 'Sample reservation only. No payment will be taken.';
const _heading = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context) => _ExperiencePage(eventId: eventId);
}

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context) =>
      _ExperiencePage(eventId: eventId, bookingOnly: true);
}

class _ExperiencePage extends StatelessWidget {
  const _ExperiencePage({required this.eventId, this.bookingOnly = false});
  final String eventId;
  final bool bookingOnly;

  Future<void> _share(BuildContext context, Event event) async {
    // Use the current route's origin rather than inventing a production domain.
    final url = Uri.base.replace(
      path: '/event/${event.id}',
      query: '',
      fragment: '',
    );
    final box = context.findRenderObject() as RenderBox?;
    try {
      await Share.share(
        '${event.title}\n$url',
        subject: event.title,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share this experience. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _findEvent(eventId);
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          title: 'Experience not found',
          message: 'Explore the sample collection for another moment.',
          actionLabel: 'All experiences',
          onAction: () => context.go('/'),
        ),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width > 800;
    final padding = desktop && width < 1100
        ? 24.0
        : AppDimensions.pagePadding(width);
    final paneHeight = math.max(
      1.0,
      MediaQuery.sizeOf(context).height -
          MediaQuery.paddingOf(context).vertical -
          150,
    );
    final related = events
        .where((e) => e.id != event.id && e.city == event.city)
        .toList(growable: false);
    final content = bookingOnly
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(event.title, style: _heading),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: EventImage(event.image, height: 300),
              ),
            ],
          )
        : _DetailContent(key: ValueKey(event.id), event: event);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: desktop ? const NeverScrollableScrollPhysics() : null,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/');
                                  }
                                },
                                icon: const Icon(
                                  Icons.arrow_back,
                                  size: 18,
                                  color: muted,
                                ),
                                label: const Text(
                                  'All experiences',
                                  style: TextStyle(color: muted, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          Builder(
                            builder: (buttonContext) => IconButton(
                              tooltip: 'Share experience',
                              onPressed: () => _share(buttonContext, event),
                              icon: const Icon(Icons.share_outlined, size: 24),
                            ),
                          ),
                          FavoriteButton(event.id),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 12, padding, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (desktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: paneHeight,
                                    child: SingleChildScrollView(
                                      key: ValueKey(
                                        'detail-scroll-${event.id}',
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          content,
                                          if (!bookingOnly)
                                            _RelatedExperiences(
                                              events: related,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 320,
                                  child: SizedBox(
                                    height: paneHeight,
                                    child: SingleChildScrollView(
                                      key: ValueKey(
                                        'booking-scroll-${event.id}',
                                      ),
                                      child: _BookingForm(
                                        key: ValueKey(event.id),
                                        event: event,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            content,
                            const SizedBox(height: 24),
                            _BookingForm(key: ValueKey(event.id), event: event),
                          ],
                          if (!bookingOnly && !desktop) ...[
                            const SizedBox(height: 32),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              children: [
                                const Text(
                                  "More moments you'll love",
                                  style: _heading,
                                ),
                                TextButton(
                                  onPressed: () => context.go('/discover'),
                                  child: const Text('Explore all →'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 430,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: related.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (_, index) {
                                  final item = related[index];
                                  return SizedBox(
                                    width: 260,
                                    child: _RelatedCard(event: item),
                                  );
                                },
                              ),
                            ),
                          ],
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

class _RelatedExperiences extends StatelessWidget {
  const _RelatedExperiences({required this.events});
  final List<Event> events;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 32),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          const Text("More moments you'll love", style: _heading),
          TextButton(
            onPressed: () => context.go('/discover'),
            child: const Text('Explore all →'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (events.isEmpty)
        const Text(
          'Explore the collection for more experiences.',
          style: AppTypography.body,
        )
      else
        SizedBox(
          height: 430,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length,
            separatorBuilder: (_, index) => const SizedBox(width: 16),
            itemBuilder: (_, index) =>
                SizedBox(width: 260, child: _RelatedCard(event: events[index])),
          ),
        ),
      const SizedBox(height: 24),
    ],
  );
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: EventCard(event, rank: event.trendingRank));
}

class _DetailContent extends ConsumerStatefulWidget {
  const _DetailContent({super.key, required this.event});
  final Event event;
  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  bool expanded = false;
  Future<void> _map() async {
    final event = widget.event;
    final url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${event.venue}, ${event.city}',
    });
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final eventReviews =
        ref.watch(eventReviewsProvider(e.id)).valueOrNull ?? reviews;
    final eventFaqs = ref.watch(eventFaqsProvider(e.id)).valueOrNull ?? faqs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              e.category.toUpperCase(),
              style: AppTypography.category.copyWith(color: gold),
            ),
            if (e.isOriginal)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: gold),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'event Original',
                  style: TextStyle(color: gold, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          e.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _Inline(Icons.star, '${e.rating}', gold),
            Text(
              '(${NumberFormat.decimalPattern('en_GB').format(e.reviewCount)} reviews)',
              style: AppTypography.body,
            ),
            _Inline(Icons.location_on_outlined, e.venue),
            _Inline(Icons.schedule, '${e.duration} minutes'),
          ],
        ),
        const SizedBox(height: 24),
        _Gallery(key: ValueKey(e.id), event: e),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Inline(Icons.check_circle_outline, 'event selection', muted, 13),
              _Inline(
                Icons.confirmation_number_outlined,
                'Mobile tickets',
                muted,
                13,
              ),
              _Inline(Icons.auto_awesome, 'Unforgettable moments', muted, 13),
            ],
          ),
        ),
        const Divider(height: 32),
        const Text('About this experience', style: _heading),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: Text(
            'Discover ${e.title} at ${e.venue}, a moment to come together and experience something different in ${e.city}. Make time for new discoveries and memories with your favourite people. This description illustrates the sample collection, not a confirmed programme. Please check the organiser’s final schedule, facilities and entry requirements before making a real purchase.',
            maxLines: expanded ? null : 4,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: AppTypography.body,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Read less' : 'Read more'),
          ),
        ),
        const Text('What makes it extraordinary', style: _heading),
        const SizedBox(height: 12),
        for (final text in [
          'An extraordinary setting, carefully chosen for the experience',
          'A beautiful way to make memories with your favourite people',
          'An intimate, immersive atmosphere from start to finish',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: gold, size: 20),
                const SizedBox(width: 16),
                Expanded(child: Text(text, style: AppTypography.body)),
              ],
            ),
          ),
        const Divider(height: 32),
        const Text('Good to know', style: _heading),
        const SizedBox(height: 20),
        const _Info(Icons.calendar_month, 'Date', 'Multiple dates available'),
        _Info(Icons.schedule, 'Duration', '${e.duration} minutes'),
        _Info(Icons.place_outlined, 'Location', e.venue),
        const _Info(
          Icons.accessible,
          'Accessibility',
          'Contact the venue for access information',
        ),
        const Divider(height: 32),
        const Text('The venue', style: _heading),
        const SizedBox(height: 16),
        MockVenueMap(events: [e], height: 180, showSelection: false),
        const SizedBox(height: 16),
        _Inline(Icons.place_outlined, e.venue, Colors.white, 18),
        Text(
          '${e.city}, ${_countryForCity(e.city)}', // رفع باگ هاردکد بودن کشورها
          style: AppTypography.body,
        ),
        const SizedBox(height: 8),
        const _Inline(
          Icons.subway_outlined,
          'Underground · nearest station within a 10-minute walk',
        ),
        const Text(
          'Illustrative travel information; check your route before travelling.',
          style: AppTypography.small,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _map,
            child: const Text('View on Google Maps →'),
          ),
        ),
        const Divider(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text('A few words from our community', style: _heading),
            ),
            const SizedBox(width: 8),
            _Inline(Icons.star, '${e.rating}', gold),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Illustrative reviews for this sample collection',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
        ),
        for (final review in reviews) ...[
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                review.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                review.date,
                style: const TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: gold, size: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.text, style: AppTypography.body),
          const Divider(height: 32),
        ],
        const Text('Your questions, answered', style: _heading),
        const SizedBox(height: 12),
        for (final faq in eventFaqs) _FaqTile(faq: faq),
      ],
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({super.key, required this.event});
  final Event event;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int selected = 0;
  @override
  void didUpdateWidget(covariant _Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    selected = oldWidget.event.id != widget.event.id
        ? 0
        : selected.clamp(0, widget.event.images.length - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.event.images;
    return Column(
      children: [
        Material(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showDialog<void>(
              context: context,
              useSafeArea: true,
              builder: (_) =>
                  _FullscreenGallery(images: images, initial: selected),
            ),
            child: Hero(
              tag: 'event-image-${widget.event.id}',
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: EventImage(
                    images[selected],
                    key: ValueKey(images[selected]),
                    height: 300,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (_, index) => Semantics(
              selected: selected == index,
              label: 'Gallery image ${index + 1}',
              button: true,
              child: SizedBox(
                width: 64,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(64, 64),
                    side: BorderSide(
                      color: selected == index ? gold : border,
                      width: selected == index ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => setState(() => selected = index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: EventImage(images[index], height: 60, width: 60),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.images, required this.initial});
  final List<String> images;
  final int initial;
  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int index = widget.initial.clamp(0, widget.images.length - 1).toInt();
  late final PageController controller = PageController(initialPage: index);

  void move(int step) {
    final target = (index + step).clamp(0, widget.images.length - 1).toInt();
    if (target == index || !controller.hasClients) return;
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: bg,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => move(1),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.pop(context),
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Gallery · ${index + 1} / ${widget.images.length}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close gallery',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (value) => setState(() => index = value),
                  itemCount: widget.images.length,
                  itemBuilder: (_, i) => InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: EventImage(
                        widget.images[i],
                        width: double.infinity,
                        height: MediaQuery.sizeOf(context).height * .7,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous image',
                    onPressed: index == 0
                        ? null
                        : () => controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const Text('Pinch to zoom'),
                  IconButton(
                    tooltip: 'Next image',
                    onPressed: index == widget.images.length - 1
                        ? null
                        : () => controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BookingForm extends ConsumerStatefulWidget {
  const _BookingForm({super.key, required this.event});
  final Event event;
  @override
  ConsumerState<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<_BookingForm> {
  late DateTime date;
  String time = '19:00';
  String ticketType = 'Standard';
  int quantity = 2;
  bool reviewing = false;
  DateTime get today => DateUtils.dateOnly(DateTime.now());
  static const slots = ['17:00', '19:00', '21:00'];

  bool available(DateTime day, String slot) {
    final parts = slot.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    ).isAfter(DateTime.now());
  }

  void selectAvailableTime() {
    if (available(date, time)) return;
    for (final slot in slots) {
      if (available(date, slot)) {
        time = slot;
        return;
      }
    }
    date = DateTime(date.year, date.month, date.day + 1);
    time = '19:00';
  }

  @override
  void initState() {
    super.initState();
    final filter = ref.read(filterDateProvider);
    final defaultDate = DateTime(2026, 10, 24);
    date = filter != null && slots.any((slot) => available(filter, slot))
        ? DateUtils.dateOnly(filter)
        : defaultDate.isBefore(today)
        ? today
        : defaultDate;
    selectAvailableTime();
  }

  Future<void> pickDate() async {
    final first = today;
    final candidate = date.isBefore(first) ? first : date;
    final initial = slots.any((slot) => available(candidate, slot))
        ? candidate
        : DateTime(candidate.year, candidate.month, candidate.day + 1);
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(math.max(first.year + 2, initial.year + 1), 12, 31),
      selectableDayPredicate: (day) =>
          slots.any((slot) => available(day, slot)),
    );
    if (mounted && picked != null) {
      setState(() {
        date = picked;
        selectAvailableTime();
      });
    }
  }

  Future<void> checkout() async {
    if (reviewing) return;
    if (!available(date, time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That start time has passed. Please choose a future date and time.',
          ),
        ),
      );
      setState(() {});
      return;
    }
    final snapshot = Reservation(
      id: 'FEV-${DateTime.now().microsecondsSinceEpoch}',
      event: widget.event,
      date: date,
      time: time,
      type: ticketType,
      quantity: quantity,
    );
    setState(() => reviewing = true);
    try {
      await _showReservation(context, snapshot);
    } finally {
      if (mounted) setState(() => reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final unitPrice = double.parse(
      (event.price * Reservation.multiplierFor(ticketType)).toStringAsFixed(2),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'YOUR NEXT UNFORGETTABLE MOMENT',
            style: AppTypography.label,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'From ${currency(event.price)}',
                  style: AppTypography.priceLarge,
                ),
                const TextSpan(text: ' / person', style: AppTypography.body),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _Inline(
            Icons.check,
            'Available in the sample collection',
            gold,
            14,
            AppColors.success,
          ),
          const SizedBox(height: 24),
          const Text('Choose your date', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: pickDate,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(shortDate(date))),
                  const Icon(Icons.calendar_month_outlined, size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Choose your time', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                for (final slot in slots) ...[
                  if (slot != '17:00') const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      selected: time == slot,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: time == slot ? gold : Colors.transparent,
                          border: Border.all(
                            color: time == slot ? gold : border,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: time == slot
                                ? AppColors.onPrimary
                                : Colors.white,
                          ),
                          onPressed: available(date, slot)
                              ? () => setState(() => time = slot)
                              : null,
                          child: Text(slot),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Ticket type', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: gold, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ticketType,
                isExpanded: true,
                items: Reservation.allowedTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          '$t (${currency(event.price * Reservation.multiplierFor(t))})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => ticketType = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(Reservation.subtitleFor(ticketType), style: AppTypography.body),
          const SizedBox(height: 20),
          const Text('Tickets', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quantityButton(
                    'Remove ticket',
                    Icons.remove,
                    quantity > 1 ? () => setState(() => quantity--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _quantityButton(
                    'Add ticket',
                    Icons.add,
                    quantity < 10 ? () => setState(() => quantity++) : null,
                  ),
                ],
              ),
              Text(
                '${currency(unitPrice)} per person',
                style: AppTypography.body,
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ($quantity ${quantity == 1 ? 'ticket' : 'tickets'})',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              Text(
                currency(unitPrice * quantity),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Get tickets →',
            height: 52,
            onPressed: reviewing ? null : checkout,
          ),
          const SizedBox(height: 12),
          const _Inline(
            Icons.info_outline,
            _disclaimer,
            AppColors.textTertiary,
            13,
            AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(String tooltip, IconData icon, VoidCallback? action) =>
      IconButton(
        tooltip: tooltip,
        onPressed: action,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          fixedSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          side: const BorderSide(color: border),
        ),
        icon: Icon(icon, size: 20),
      );
}

Future<void> _showReservation(BuildContext context, Reservation reservation) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Close reservation',
      barrierColor: AppColors.overlay,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, animation, secondary, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      ),
      pageBuilder: (_, animation, secondary) =>
          _ReservationDialog(reservation: reservation),
    );

class _ReservationDialog extends ConsumerStatefulWidget {
  const _ReservationDialog({required this.reservation});
  final Reservation reservation;
  @override
  ConsumerState<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends ConsumerState<_ReservationDialog>
    with SingleTickerProviderStateMixin {
  AsyncValue<Reservation?> status = const AsyncData(null);
  bool get confirmed => status.asData?.value != null;
  late final AnimationController animation;
  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  Future<void> confirm() async {
    if (confirmed || status.isLoading) return;
    setState(() => status = const AsyncLoading());
    try {
      final reservation = await ref
          .read(bookingRepositoryProvider)
          .confirm(widget.reservation);
      if (!mounted) return;
      ref
          .read(ticketsProvider.notifier)
          .update(
            (tickets) => tickets.any((ticket) => ticket.id == reservation.id)
                ? tickets
                : [...tickets, reservation],
          );
      setState(() => status = AsyncData(reservation));
      animation.forward(from: 0);
    } catch (error, stack) {
      if (mounted) setState(() => status = AsyncError(error, stack));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PopScope(
        canPop: !status.isLoading,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: status.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
                    ),
                    Text(
                      confirmed
                          ? 'A good plan is on the cards.'
                          : 'Your experience, all set.',
                      style: _heading.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      confirmed
                          ? 'Your sample reservation has been added to your tickets.'
                          : 'Review your sample reservation. This is not a real purchase.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),
                    if (confirmed)
                      Center(
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (_, child) => CustomPaint(
                            size: const Size(64, 64),
                            painter: _SuccessPainter(animation.value),
                          ),
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: EventImage(
                          r.event.image,
                          height: 180,
                          width: double.infinity,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      r.event.title,
                      style: TextStyle(
                        color: confirmed ? Colors.white : gold,
                        fontWeight: FontWeight.bold,
                        fontSize: confirmed ? 16 : 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (confirmed)
                      Text(
                        '${dateLabel(r.date)} · ${r.time} · ${r.quantity} × ${r.type}',
                        style: AppTypography.body,
                      )
                    else ...[
                      _DetailRow(
                        'Date & time',
                        '${isoDate(r.date)} · ${r.time}',
                      ),
                      _DetailRow('Tickets', '${r.quantity} × ${r.type}'),
                      const _DetailRow('Admission', 'General admission'),
                      _DetailRow('Sample total', currency(r.total), gold),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      confirmed
                          ? _disclaimer
                          : 'This reservation stays only during your current visit. Real booking and payment services are not connected.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (status.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: gold),
                        ),
                      ),
                    if (status.hasError) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          status.error is BookingValidationFailure
                              ? (status.error as BookingValidationFailure)
                                    .message
                              : 'Unable to create your sample reservation. Please retry or cancel.',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      height: 52,
                      label: confirmed
                          ? 'View my tickets →'
                          : status.isLoading
                          ? 'Confirming sample reservation…'
                          : status.hasError
                          ? 'Retry sample reservation →'
                          : 'Confirm sample reservation →',
                      onPressed: status.isLoading
                          ? null
                          : confirmed
                          ? () {
                              Navigator.pop(context);
                              context.go('/tickets');
                            }
                          : confirm,
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

class _SuccessPainter extends CustomPainter {
  const _SuccessPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      -math.pi / 2,
      2 * math.pi * (progress / .65).clamp(0.0, 1.0),
      false,
      paint,
    );
    final check = Path()
      ..moveTo(18, 33)
      ..lineTo(28, 43)
      ..lineTo(47, 23);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(
        0,
        metric.length * ((progress - .65) / .35).clamp(0.0, 1.0),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SuccessPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, [this.color = muted]);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTypography.body)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: color == gold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Inline extends StatelessWidget {
  const _Inline(
    this.icon,
    this.text, [
    this.color = muted,
    this.fontSize = 14,
    this.iconColor = gold,
  ]);
  final IconData icon;
  final String text;
  final Color color, iconColor;
  final double fontSize;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: fontSize, height: 1.6),
        ),
      ),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: gold, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(value, style: AppTypography.body),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq});
  final Faq faq;
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () => setState(() => expanded = !expanded),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.faq.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: expanded ? .5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.keyboard_arrow_down, color: muted),
            ),
          ],
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.topCenter,
        child: expanded
            ? Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.faq.answer, style: AppTypography.body),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const Divider(height: 1),
    ],
  );
}
