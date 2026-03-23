/// UV-координаты прямоугольника на текстуре с указанием атласа.
class RectUV {
  final int atlasId;    // идентификатор атласа (0, 1, 2...)
  final double left;
  final double top;
  final double right;
  final double bottom;

  const RectUV(this.atlasId, this.left, this.top, this.right, this.bottom);

  double get width => right - left;
  double get height => bottom - top;

  @override
  String toString() => 'RectUV($atlasId, $left, $top, $right, $bottom)';
}