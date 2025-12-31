class MediaModel {
  int? id;
  int? artistId;
  String? artistName;
  String? mediaType;
  String? mediaUrl;
  String? caption;
  int? likeCount;
  int? commentsCount;
  int? sharesCount;
  String? createdAt;

  MediaModel({
    this.id,
    this.artistId,
    this.artistName,
    this.mediaType,
    this.mediaUrl,
    this.caption,
    this.likeCount,
    this.commentsCount,
    this.sharesCount,
    this.createdAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      artistId: int.tryParse(json['artist_id'].toString()) ?? 0,
      artistName: json['artist_name']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      likeCount: int.tryParse(json['like_count']?.toString() ?? '0') ?? 0,
      commentsCount: int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      sharesCount: int.tryParse(json['shares_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}