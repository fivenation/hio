import 'package:hio/graphics/blocks/models/block_defenition.dart';
import 'package:hio/graphics/core/rect_uv.dart';

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
  
  factory BlockTextures.uniform(RectUV uv) {
    return BlockTextures(
      top: uv,
      bottom: uv,
      north: uv,
      south: uv,
      east: uv,
      west: uv,
    );
  }
  
  RectUV? getFace(FaceDirection direction) {
    switch (direction) {
      case FaceDirection.top:
        return top;
      case FaceDirection.bottom:
        return bottom;
      case FaceDirection.north:
        return north;
      case FaceDirection.south:
        return south;
      case FaceDirection.east:
        return east;
      case FaceDirection.west:
        return west;
    }
  }
}