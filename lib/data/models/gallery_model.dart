import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_model.g.dart';

@JsonSerializable()
class GeneratedImage {
  final String id;
  final String userId;
  @JsonKey(fromJson: _resolveUrl)
  final String imageUrl;
  final String? prompt;
  final String? negativePrompt;
  final String workflow;
  final int? seed;
  final bool isFavorite;
  final bool isShared;
  final bool isLocked;
  final String? communityPostId;

  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime? createdAt;

  // Sync with NetworkModule._baseUrl
  static const String _baseUrl = "https://drawai-api.drawai.site";

  GeneratedImage({
    this.id = '',
    this.userId = '',
    this.imageUrl = '',
    this.prompt,
    this.negativePrompt,
    this.workflow = 'standard',
    this.seed,
    this.isFavorite = false,
    this.isShared = false,
    this.isLocked = false,
    this.communityPostId,
    this.createdAt,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) =>
      _$GeneratedImageFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratedImageToJson(this);

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

  GeneratedImage copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? prompt,
    String? negativePrompt,
    String? workflow,
    int? seed,
    bool? isFavorite,
    bool? isShared,
    bool? isLocked,
    String? communityPostId,
    DateTime? createdAt,
  }) {
    return GeneratedImage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      workflow: workflow ?? this.workflow,
      seed: seed ?? this.seed,
      isFavorite: isFavorite ?? this.isFavorite,
      isShared: isShared ?? this.isShared,
      isLocked: isLocked ?? this.isLocked,
      communityPostId: communityPostId ?? this.communityPostId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
