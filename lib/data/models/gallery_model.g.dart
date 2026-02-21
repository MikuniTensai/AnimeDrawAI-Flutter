// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedImage _$GeneratedImageFromJson(Map<String, dynamic> json) =>
    GeneratedImage(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imageUrl: json['imageUrl'] == null
          ? ''
          : GeneratedImage._resolveUrl(json['imageUrl'] as String),
      prompt: json['prompt'] as String?,
      negativePrompt: json['negativePrompt'] as String?,
      workflow: json['workflow'] as String? ?? 'standard',
      seed: (json['seed'] as num?)?.toInt(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isShared: json['isShared'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      communityPostId: json['communityPostId'] as String?,
      createdAt: GeneratedImage._dateTimeFromTimestamp(json['createdAt']),
    );

Map<String, dynamic> _$GeneratedImageToJson(GeneratedImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'imageUrl': instance.imageUrl,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'workflow': instance.workflow,
      'seed': instance.seed,
      'isFavorite': instance.isFavorite,
      'isShared': instance.isShared,
      'isLocked': instance.isLocked,
      'communityPostId': instance.communityPostId,
      'createdAt': GeneratedImage._dateTimeToTimestamp(instance.createdAt),
    };
