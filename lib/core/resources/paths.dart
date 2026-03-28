class Paths {
  static const String _base = 'resources/';
  static const String data = '${_base}data/';
  static const String images = '${_base}images/';
  static const String blocks = '${data}blocks.json';
  
  static const String textures = '${images}textures/';

  static String objectJson(int objectId) {
    return '${data}objects/${objectId}_chest.json';
  }

  static String image(String relativePath) {
    return images + relativePath;
  }
  
  static String texture(String fileName) {
    return textures + fileName;
  }
}