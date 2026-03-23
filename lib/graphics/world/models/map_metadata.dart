class MapMetadata {
  final String name;
  final String displayName;
  final String? previewImage;

  const MapMetadata({
    required this.name,
    required this.displayName,
    this.previewImage,
  });

  factory MapMetadata.fromJson(Map<String, dynamic> json) {
    return MapMetadata(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      previewImage: json['previewImage'] as String?,
    );
  }
}
