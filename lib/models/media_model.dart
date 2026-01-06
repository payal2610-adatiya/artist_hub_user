class MediaModel {
  int id;
  int artistId;
  String artistName;
  String mediaType;
  String mediaUrl;
  String caption;
  int likeCount;
  DateTime createdAt;

  MediaModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.mediaType,
    required this.mediaUrl,
    required this.caption,
    required this.likeCount,
    required this.createdAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: int.parse(json['id'].toString()),
      artistId: int.parse(json['artist_id'].toString()),
      artistName: json['artist_name'] ?? '',
      mediaType: json['media_type'] ?? '',
      mediaUrl: json['media_url'] ?? '',
      caption: json['caption'] ?? '',
      likeCount: int.parse((json['like_count'] ?? 0).toString()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artist_id': artistId,
      'artist_name': artistName,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'caption': caption,
      'like_count': likeCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}