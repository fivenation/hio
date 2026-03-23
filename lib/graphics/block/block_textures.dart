import '../../graphics/core/rect_uv.dart';

class BlockTextures {
  final RectUV top;
  final RectUV bottom;
  final RectUV north;
  final RectUV south;
  final RectUV east;
  final RectUV west;

  const BlockTextures({
    required this.top,
    required this.bottom,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory BlockTextures.uniform(RectUV rect) {
    return BlockTextures(
      top: rect,
      bottom: rect,
      north: rect,
      south: rect,
      east: rect,
      west: rect,
    );
  }
}