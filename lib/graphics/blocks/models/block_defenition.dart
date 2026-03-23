import 'dart:ui';
import 'block_textures.dart';

class BlockDefinition {
  final int id;
  final String name;
  final bool isSolid;
  final BlockTextures? textures;
  final Color color;

  const BlockDefinition({
    required this.id,
    required this.name,
    required this.isSolid,
    this.textures,
    required this.color,
  });
}