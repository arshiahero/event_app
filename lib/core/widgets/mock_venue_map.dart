import '../shared.dart';
import '../../data/catalog.dart';

/// An offline design preview. Marker positions are illustrative, not navigation data.
class MockVenueMap extends StatefulWidget {
  const MockVenueMap({
    super.key,
    required this.events,
    this.height = 420,
    this.showSelection = true,
  });
  final List<Event> events;
  final double height;
  final bool showSelection;
  @override
  State<MockVenueMap> createState() => _MockVenueMapState();
}

class _MockVenueMapState extends State<MockVenueMap> {
  int selected = 0;
  final transform = TransformationController();
  double zoom = 1;
  @override
  void didUpdateWidget(covariant MockVenueMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selected >= widget.events.length) selected = 0;
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void _zoom(double step) {
    zoom = (zoom + step).clamp(1, 3);
    transform.value = Matrix4.diagonal3Values(zoom, zoom, 1);
  }

  @override
  Widget build(BuildContext context) => Container(
    height: widget.height,
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      border: Border.all(color: widget.showSelection ? border : gold),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          InteractiveViewer(
            transformationController: transform,
            minScale: 1,
            maxScale: 3,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _MapPainter()),
                  ),
                  if (!widget.showSelection)
                    const Center(
                      child: Icon(Icons.location_on, color: gold, size: 40),
                    ),
                  for (
                    var i = 0;
                    widget.showSelection && i < widget.events.length;
                    i++
                  )
                    Positioned(
                      left: (constraints.maxWidth - 110) * (.12 + (i % 3) * .3),
                      top:
                          55 +
                          (constraints.maxHeight - 200).clamp(0, 220) *
                              ((i ~/ 3) % 3) /
                              3 +
                          (i % 2) * 40,
                      child: Semantics(
                        label:
                            '${widget.events[i].venue}, ${currency(widget.events[i].price)}',
                        selected: i == selected,
                        child: Material(
                          color: i == selected ? gold : bg,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(100),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(100),
                            onTap: () => setState(() => selected = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              height: 44,
                              decoration: BoxDecoration(
                                border: Border.all(color: gold),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: i == selected
                                        ? AppColors.onPrimary
                                        : gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    currency(widget.events[i].price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: i == selected
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
            ),
          ),
          if (widget.showSelection)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: border),
                ),
                child: Column(
                  children: [
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () => _zoom(.25),
                      icon: const Icon(Icons.add, color: gold),
                    ),
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () => _zoom(-.25),
                      icon: const Icon(Icons.remove, color: gold),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showSelection && widget.events.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 32,
              child: Material(
                color: bg,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      context.push('/event/${widget.events[selected].id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: EventImage(
                            widget.events[selected].image,
                            width: 64,
                            height: 64,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.events[selected].title,
                                style: AppTypography.cardTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.events[selected].venue,
                                style: AppTypography.small,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'From ${currency(widget.events[selected].price)}',
                                style: AppTypography.rating,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: gold),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: bg.withValues(alpha: .8),
              child: const Text(
                'Illustrative map · sample positions',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  const _MapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF102929),
    );
    final blocks = Paint()..color = const Color(0xFF183434);
    for (double x = -20; x < size.width; x += 85) {
      for (double y = 0; y < size.height; y += 70) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 8, y + 8, 65, 50),
            const Radius.circular(6),
          ),
          blocks,
        );
      }
    }
    final roads = Paint()
      ..color = const Color(0xFF375353)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    for (double x = -100; x < size.width + 100; x += 120) {
      canvas.drawLine(Offset(x, 0), Offset(x + 140, size.height), roads);
    }
    for (double y = 40; y < size.height; y += 90) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 50), roads);
    }
    final river = Path()
      ..moveTo(-30, size.height * .65)
      ..cubicTo(
        size.width * .25,
        size.height * .25,
        size.width * .5,
        size.height * .9,
        size.width + 30,
        size.height * .45,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF1C5261)
        ..strokeWidth = 34
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF30707B)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    final text = TextPainter(
      text: const TextSpan(
        text: 'CITY WATERFRONT',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          color: Color(0xFF89AFB5),
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(size.width * .32, size.height * .57));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
