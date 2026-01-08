//
// lib/models/media_model.dart
class MediaModel {
  int id;
  int artistId;
  String artistName;
  String mediaType;
  String mediaUrl;
  String caption;
  int likeCount;
  int commentCount;
  int shareCount;
  DateTime createdAt;

  MediaModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.mediaType,
    required this.mediaUrl,
    required this.caption,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.createdAt,
  });
  MediaModel copyWith({
    int? id,
    int? artistId,
    String? artistName,
    String? mediaType,
    String? mediaUrl,
    String? caption,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    DateTime? createdAt,
  }) {
    return MediaModel(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: int.parse(json['id'].toString()),
      artistId: int.parse(json['artist_id'].toString()),
      artistName: json['artist_name'] ?? 'Unknown Artist',
      mediaType: json['media_type'] ?? 'image',
      mediaUrl: json['media_url'] ?? '',
      caption: json['caption'] ?? '',
      likeCount: int.parse((json['like_count'] ?? json['total_likes'] ?? '0').toString()),
      commentCount: int.parse((json['comment_count'] ?? json['total_comments'] ?? '0').toString()),
      shareCount: int.parse((json['share_count'] ?? json['total_shares'] ?? '0').toString()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
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
      'comment_count': commentCount,
      'share_count': shareCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}