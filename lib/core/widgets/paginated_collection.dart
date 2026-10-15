import 'dart:async';
import '../shared.dart';
import '../../data/catalog.dart';

/// Pages the finite mock collection without duplicating events or inventing inventory.
class PaginatedCollection extends StatefulWidget {
  const PaginatedCollection({
    super.key,
    required this.items,
    required this.builder,
    this.pageSize = 4,
  });
  final List<Event> items;
  final Widget Function(List<Event>) builder;
  final int pageSize;
  @override
  State<PaginatedCollection> createState() => _PaginatedCollectionState();
}

class _PaginatedCollectionState extends State<PaginatedCollection> {
  late int visible = widget.pageSize;
  bool loading = false;
  int generation = 0;
  ScrollPosition? position;
  Timer? pending;
  String _signature(List<Event> items) =>
      items.map((e) => '${e.id}:${e.price}').join('|');
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (next != position) {
      position?.removeListener(_onScroll);
      position = next;
      position?.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(covariant PaginatedCollection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.items) != _signature(widget.items) ||
        oldWidget.pageSize != widget.pageSize) {
      generation++;
      pending?.cancel();
      visible = widget.pageSize;
      loading = false;
    }
  }

  void _onScroll() {
    final scroll = position;
    if (scroll != null &&
        scroll.hasContentDimensions &&
        scroll.pixels > 0 &&
        scroll.extentAfter < 280)
      _loadMore();
  }

  void _loadMore() {
    if (loading || visible >= widget.items.length) return;
    final request = generation;
    setState(() => loading = true);
    pending = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || request != generation) return;
      setState(() {
        visible = (visible + widget.pageSize).clamp(0, widget.items.length);
        loading = false;
      });
    });
  }

  @override
  void dispose() {
    generation++;
    pending?.cancel();
    position?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      widget.builder(widget.items.take(visible).toList()),
      if (loading)
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: LoadingSkeleton(height: 80),
        )
      else if (visible < widget.items.length)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: OutlinedButton(
              onPressed: _loadMore,
              child: Text('Discover more (${widget.items.length - visible}) →'),
            ),
          ),
        )
      else if (widget.items.length > widget.pageSize)
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text(
            'You’re all caught up with this collection.',
            textAlign: TextAlign.center,
            style: AppTypography.small,
          ),
        ),
    ],
  );
}
