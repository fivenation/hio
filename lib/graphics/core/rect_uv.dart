class RectUV {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const RectUV(
    this.left,
    this.top,
    this.right,
    this.bottom,
  );

  double get width => right - left;
  double get height => bottom - top;

  @override
  String toString() => 'RectUV(left: $left, top: $top, right: $right, bottom: $bottom)';
}