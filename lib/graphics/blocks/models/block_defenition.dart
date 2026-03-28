import 'dart:ui';
import 'package:hio/graphics/core/rect_uv.dart';

import 'block_textures.dart';

class BlockDefinition {
  final int id;
  final String name;
  final bool isSolid;
  final BlockTextures? textures;  // Теперь опциональный
  final Color color;              // Fallback цвет, если нет текстур

  const BlockDefinition({
    required this.id,
    required this.name,
    required this.isSolid,
    this.textures,
    required this.color,
  });

  factory BlockDefinition.uniform({
    required int id,
    required String name,
    required bool isSolid,
    required RectUV uv,
    required Color color,
  }) {
    return BlockDefinition(
      id: id,
      name: name,
      isSolid: isSolid,
      textures: BlockTextures.uniform(uv),
      color: color,
    );
  }

  bool get hasTextures => textures != null;
  
  RectUV? getFaceUV(FaceDirection direction) {
    return textures?.getFace(direction);
  }
}

enum FaceDirection { top, bottom, north, south, east, west }