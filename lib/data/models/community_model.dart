import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'community_model.g.dart';

enum SortType {
  @JsonValue('POPULAR')
  popular,
  @JsonValue('RECENT')
  recent,
  @JsonValue('TRENDING')
  trending,
  @JsonValue('MY_POSTS')
  myPosts,
}

@JsonSerializable()
class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  @JsonKey(fromJson: _resolveUrl)
  final String imageUrl;
  @JsonKey(fromJson: _resolveUrl)
  final String thumbnailUrl;
  final String prompt;
  final String negativePrompt;
  final String workflow;
  final int likes;
  final int downloads;
  final int views;
  final List<String>? tags;
  final String? category;

  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime? createdAt;

  final bool isReported;
  final int reportCount;

  CommunityPost({
    this.id = '',
    this.userId = '',
    this.username = '',
    this.userPhotoUrl,
    this.imageUrl = '',
    this.thumbnailUrl = '',
    this.prompt = '',
    this.negativePrompt = '',
    this.workflow = '',
    this.likes = 0,
    this.downloads = 0,
    this.views = 0,
    this.tags,
    this.category,
    this.createdAt,
    this.isReported = false,
    this.reportCount = 0,
  });

  // Sync with NetworkModule._baseUrl
  static const String _baseUrl = "https://drawai-api.drawai.site";

  factory CommunityPost.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostFromJson(json);
  Map<String, dynamic> toJson() => _$CommunityPostToJson(this);

  static String _resolveUrl(String url) {
    if (url.startsWith('/')) {
      return "$_baseUrl$url";
    }
    return url;
  }

  static DateTime? _dateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return null;
  }

  static dynamic _dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? imageUrl,
    String? thumbnailUrl,
    String? prompt,
    String? negativePrompt,
    String? workflow,
    int? likes,
    int? downloads,
    int? views,
    List<String>? tags,
    String? category,
    DateTime? createdAt,
    bool? isReported,
    int? reportCount,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      workflow: workflow ?? this.workflow,
      likes: likes ?? this.likes,
      downloads: downloads ?? this.downloads,
      views: views ?? this.views,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isReported: isReported ?? this.isReported,
      reportCount: reportCount ?? this.reportCount,
    );
  }
}
