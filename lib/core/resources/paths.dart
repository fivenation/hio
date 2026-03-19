class Paths {
  static const String data = 'resources/data/';
  static const String images = 'resources/images/';

  static String objectJson(int objectId) {
    return '${data}objects/${objectId}_chest.json';
  }

  static String image(String relativePath) {
    return images + relativePath;
  }
}
