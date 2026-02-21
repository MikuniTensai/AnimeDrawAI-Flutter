// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharacterModel _$CharacterModelFromJson(Map<String, dynamic> json) =>
    CharacterModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imageId: json['imageId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      imageStorageUrl: json['imageStorageUrl'] as String?,
      prompt: json['prompt'] as String? ?? '',
      seed: (json['seed'] as num?)?.toInt(),
      workflow: json['workflow'] as String?,
      personality: CharacterPersonality.fromJson(
        json['personality'] as Map<String, dynamic>,
      ),
      relationship: RelationshipStatus.fromJson(
        json['relationship'] as Map<String, dynamic>,
      ),
      emotionalState: EmotionalState.fromJson(
        json['emotionalState'] as Map<String, dynamic>,
      ),
      interactionPatterns: InteractionPatterns.fromJson(
        json['interactionPatterns'] as Map<String, dynamic>,
      ),
      createdAt: json['createdAt'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      isDeleted: json['isDeleted'] as bool? ?? false,
      notificationEnabled: json['notificationEnabled'] as bool? ?? false,
      notificationUnlocked: json['notificationUnlocked'] as bool? ?? false,
      profileUpdatedAt: json['profileUpdatedAt'] as String?,
    );

Map<String, dynamic> _$CharacterModelToJson(CharacterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'imageId': instance.imageId,
      'imageUrl': instance.imageUrl,
      'imageStorageUrl': instance.imageStorageUrl,
      'prompt': instance.prompt,
      'seed': instance.seed,
      'workflow': instance.workflow,
      'personality': instance.personality,
      'relationship': instance.relationship,
      'emotionalState': instance.emotionalState,
      'interactionPatterns': instance.interactionPatterns,
      'createdAt': instance.createdAt,
      'language': instance.language,
      'isDeleted': instance.isDeleted,
      'notificationEnabled': instance.notificationEnabled,
      'notificationUnlocked': instance.notificationUnlocked,
      'profileUpdatedAt': instance.profileUpdatedAt,
    };

CharacterPersonality _$CharacterPersonalityFromJson(
  Map<String, dynamic> json,
) => CharacterPersonality(
  archetype: json['archetype'] as String? ?? '',
  traits:
      (json['traits'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  background: json['background'] as String? ?? '',
  communicationStyle: json['communicationStyle'] as String? ?? '',
  interests:
      (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  appearance: json['appearance'] as String? ?? '',
  rarity: json['rarity'] as String? ?? 'Common',
  sinCount: (json['sinCount'] as num?)?.toInt() ?? 0,
  name: json['name'] as String? ?? '',
  gender: json['gender'] as String? ?? 'female',
);

Map<String, dynamic> _$CharacterPersonalityToJson(
  CharacterPersonality instance,
) => <String, dynamic>{
  'archetype': instance.archetype,
  'traits': instance.traits,
  'background': instance.background,
  'communicationStyle': instance.communicationStyle,
  'interests': instance.interests,
  'appearance': instance.appearance,
  'rarity': instance.rarity,
  'sinCount': instance.sinCount,
  'name': instance.name,
  'gender': instance.gender,
};

RelationshipStatus _$RelationshipStatusFromJson(
  Map<String, dynamic> json,
) => RelationshipStatus(
  stage: json['stage'] == null
      ? RelationshipStage.stranger
      : const RelationshipStageConverter().fromJson(json['stage'] as String),
  stageProgress: (json['stageProgress'] as num?)?.toInt() ?? 0,
  affectionPoints: (json['affectionPoints'] as num?)?.toDouble() ?? 0.0,
  nextStageThreshold: (json['nextStageThreshold'] as num?)?.toInt() ?? 500,
  totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
  lastInteraction: RelationshipStatus._dateTimeFromTimestamp(
    json['lastInteraction'],
  ),
  lastChatDate: RelationshipStatus._dateTimeFromTimestamp(json['lastChatDate']),
  upgradeAvailable: json['upgradeAvailable'] as bool? ?? false,
);

Map<String, dynamic> _$RelationshipStatusToJson(RelationshipStatus instance) =>
    <String, dynamic>{
      'stage': const RelationshipStageConverter().toJson(instance.stage),
      'stageProgress': instance.stageProgress,
      'affectionPoints': instance.affectionPoints,
      'nextStageThreshold': instance.nextStageThreshold,
      'totalMessages': instance.totalMessages,
      'lastInteraction': RelationshipStatus._timestampFromDateTime(
        instance.lastInteraction,
      ),
      'lastChatDate': RelationshipStatus._timestampFromDateTime(
        instance.lastChatDate,
      ),
      'upgradeAvailable': instance.upgradeAvailable,
    };

EmotionalState _$EmotionalStateFromJson(Map<String, dynamic> json) =>
    EmotionalState(
      currentMood: json['currentMood'] as String? ?? 'neutral',
      energyLevel: (json['energyLevel'] as num?)?.toInt() ?? 80,
      lastMoodChange: RelationshipStatus._dateTimeFromTimestamp(
        json['lastMoodChange'],
      ),
    );

Map<String, dynamic> _$EmotionalStateToJson(EmotionalState instance) =>
    <String, dynamic>{
      'currentMood': instance.currentMood,
      'energyLevel': instance.energyLevel,
      'lastMoodChange': RelationshipStatus._timestampFromDateTime(
        instance.lastMoodChange,
      ),
    };

InteractionPatterns _$InteractionPatternsFromJson(Map<String, dynamic> json) =>
    InteractionPatterns(
      totalGhostsDetected: (json['totalGhostsDetected'] as num?)?.toInt() ?? 0,
      averageResponseTime:
          (json['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      chatFrequency: json['chatFrequency'] as String? ?? 'daily',
      lastGhostWarning: json['lastGhostWarning'] as String?,
    );

Map<String, dynamic> _$InteractionPatternsToJson(
  InteractionPatterns instance,
) => <String, dynamic>{
  'totalGhostsDetected': instance.totalGhostsDetected,
  'averageResponseTime': instance.averageResponseTime,
  'chatFrequency': instance.chatFrequency,
  'lastGhostWarning': instance.lastGhostWarning,
};

CharacterMessage _$CharacterMessageFromJson(Map<String, dynamic> json) =>
    CharacterMessage(
      id: json['id'] as String? ?? '',
      characterId: json['characterId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: RelationshipStatus._dateTimeFromTimestamp(json['timestamp']),
      relationshipStage: json['relationshipStage'] == null
          ? RelationshipStage.stranger
          : const RelationshipStageConverter().fromJson(
              json['relationshipStage'] as String,
            ),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$CharacterMessageToJson(
  CharacterMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'characterId': instance.characterId,
  'userId': instance.userId,
  'role': instance.role,
  'content': instance.content,
  'timestamp': RelationshipStatus._timestampFromDateTime(instance.timestamp),
  'relationshipStage': const RelationshipStageConverter().toJson(
    instance.relationshipStage,
  ),
  'imageUrl': instance.imageUrl,
};
