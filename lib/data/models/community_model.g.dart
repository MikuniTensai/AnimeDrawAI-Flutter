// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityPost _$CommunityPostFromJson(Map<String, dynamic> json) =>
    CommunityPost(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      imageUrl: json['imageUrl'] == null
          ? ''
          : CommunityPost._resolveUrl(json['imageUrl'] as String),
      thumbnailUrl: json['thumbnailUrl'] == null
          ? ''
          : CommunityPost._resolveUrl(json['thumbnailUrl'] as String),
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      workflow: json['workflow'] as String? ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      category: json['category'] as String?,
      createdAt: CommunityPost._dateTimeFromTimestamp(json['createdAt']),
      isReported: json['isReported'] as bool? ?? false,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CommunityPostToJson(CommunityPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'userPhotoUrl': instance.userPhotoUrl,
      'imageUrl': instance.imageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'workflow': instance.workflow,
      'likes': instance.likes,
      'downloads': instance.downloads,
      'views': instance.views,
      'tags': instance.tags,
      'category': instance.category,
      'createdAt': CommunityPost._dateTimeToTimestamp(instance.createdAt),
      'isReported': instance.isReported,
      'reportCount': instance.reportCount,
    };
