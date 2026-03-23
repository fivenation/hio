import 'block_textures.dart';

class BlockDefinition {
  final int id;
  final String name;
  final bool isSolid;
  final BlockTextures textures;

  const BlockDefinition({
    required this.id,
    required this.name,
    required this.isSolid,
    required this.textures,
  });
}