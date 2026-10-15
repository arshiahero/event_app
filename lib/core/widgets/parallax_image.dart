import '../shared.dart';

class ParallaxImage extends StatelessWidget {
  const ParallaxImage(this.path, {super.key});
  final String path;
  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (scrollable == null || MediaQuery.disableAnimationsOf(context)) {
      return EventImage(path, width: double.infinity, height: double.infinity);
    }
    return ClipRect(
      child: Flow(
        delegate: _ParallaxDelegate(scrollable.position),
        children: [
          EventImage(path, width: double.infinity, height: double.infinity),
        ],
      ),
    );
  }
}

class _ParallaxDelegate extends FlowDelegate {
  _ParallaxDelegate(this.position) : super(repaint: position);
  final ScrollPosition position;
  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(
        Size(constraints.maxWidth, constraints.maxHeight + 40),
      );
  @override
  void paintChildren(FlowPaintingContext context) {
    final range = position.maxScrollExtent + position.viewportDimension;
    final fraction = range <= 0
        ? 0.0
        : (position.pixels / range).clamp(0.0, 1.0);
    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, -40 * fraction, 0),
    );
  }

  @override
  bool shouldRepaint(covariant _ParallaxDelegate oldDelegate) =>
      position != oldDelegate.position;
}
