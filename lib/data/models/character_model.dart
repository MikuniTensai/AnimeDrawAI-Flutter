import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'character_model.g.dart';

@JsonSerializable()
class CharacterModel {
  final String id;
  final String userId;
  final String imageId;
  final String imageUrl;
  final String? imageStorageUrl;
  final String prompt;
  final int? seed;
  final String? workflow;
  final CharacterPersonality personality;
  @RelationshipStageConverter()
  final RelationshipStatus relationship;
  final EmotionalState emotionalState;
  final InteractionPatterns interactionPatterns;
  final String createdAt;
  final String language;
  final bool isDeleted;
  final bool notificationEnabled;
  final bool notificationUnlocked;
  final String? profileUpdatedAt;

  CharacterModel({
    this.id = '',
    this.userId = '',
    this.imageId = '',
    this.imageUrl = '',
    this.imageStorageUrl,
    this.prompt = '',
    this.seed,
    this.workflow,
    required this.personality,
    required this.relationship,
    required this.emotionalState,
    required this.interactionPatterns,
    this.createdAt = '',
    this.language = 'en',
    this.isDeleted = false,
    this.notificationEnabled = false,
    this.notificationUnlocked = false,
    this.profileUpdatedAt,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterModelFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterModelToJson(this);
}

@JsonSerializable()
class CharacterPersonality {
  final String archetype;
  final List<String> traits;
  final String background;
  final String communicationStyle;
  final List<String> interests;
  final String appearance;
  final String rarity;
  final int sinCount;
  final String name;
  final String gender;

  CharacterPersonality({
    this.archetype = '',
    this.traits = const [],
    this.background = '',
    this.communicationStyle = '',
    this.interests = const [],
    this.appearance = '',
    this.rarity = 'Common',
    this.sinCount = 0,
    this.name = '',
    this.gender = 'female',
  });

  factory CharacterPersonality.fromJson(Map<String, dynamic> json) =>
      _$CharacterPersonalityFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterPersonalityToJson(this);
}

@JsonSerializable()
class RelationshipStatus {
  @RelationshipStageConverter()
  final RelationshipStage stage;
  final int stageProgress;
  final double affectionPoints;
  final int nextStageThreshold;
  final int totalMessages;
  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _timestampFromDateTime)
  final DateTime? lastInteraction;
  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _timestampFromDateTime)
  final DateTime? lastChatDate;
  final bool upgradeAvailable;

  RelationshipStatus({
    this.stage = RelationshipStage.stranger,
    this.stageProgress = 0,
    this.affectionPoints = 0.0,
    this.nextStageThreshold = 500,
    this.totalMessages = 0,
    this.lastInteraction,
    this.lastChatDate,
    this.upgradeAvailable = false,
  });

  factory RelationshipStatus.fromJson(Map<String, dynamic> json) =>
      _$RelationshipStatusFromJson(json);
  Map<String, dynamic> toJson() => _$RelationshipStatusToJson(this);

  static DateTime? _dateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  static dynamic _timestampFromDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}

class RelationshipStageConverter
    implements JsonConverter<RelationshipStage, String> {
  const RelationshipStageConverter();

  @override
  RelationshipStage fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'stranger':
        return RelationshipStage.stranger;
      case 'friend':
        return RelationshipStage.friend;
      case 'best_friend':
        return RelationshipStage.bestFriend;
      case 'romantic':
        return RelationshipStage.romantic;
      case 'married':
        return RelationshipStage.married;
      default:
        return RelationshipStage.stranger;
    }
  }

  @override
  String toJson(RelationshipStage stage) {
    switch (stage) {
      case RelationshipStage.stranger:
        return 'stranger';
      case RelationshipStage.friend:
        return 'friend';
      case RelationshipStage.bestFriend:
        return 'best_friend';
      case RelationshipStage.romantic:
        return 'romantic';
      case RelationshipStage.married:
        return 'married';
    }
  }
}

enum RelationshipStage {
  @JsonValue('stranger')
  stranger,
  @JsonValue('friend')
  friend,
  @JsonValue('best_friend')
  bestFriend,
  @JsonValue('romantic')
  romantic,
  @JsonValue('married')
  married;

  String get displayName {
    switch (this) {
      case RelationshipStage.stranger:
        return 'Stranger';
      case RelationshipStage.friend:
        return 'Friend';
      case RelationshipStage.bestFriend:
        return 'Best Friend';
      case RelationshipStage.romantic:
        return 'Romantic';
      case RelationshipStage.married:
        return 'Married';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipStage.stranger:
        return '👤';
      case RelationshipStage.friend:
        return '👋';
      case RelationshipStage.bestFriend:
        return '🌟';
      case RelationshipStage.romantic:
        return '❤️';
      case RelationshipStage.married:
        return '💍';
    }
  }

  int get color {
    switch (this) {
      case RelationshipStage.stranger:
        return 0xFF9E9E9E; // Grey
      case RelationshipStage.friend:
        return 0xFF4CAF50; // Green
      case RelationshipStage.bestFriend:
        return 0xFF2196F3; // Blue
      case RelationshipStage.romantic:
        return 0xFFE91E63; // Pink
      case RelationshipStage.married:
        return 0xFFFFD700; // Gold
    }
  }
}

@JsonSerializable()
class EmotionalState {
  final String currentMood;
  final int energyLevel;
  @JsonKey(
    fromJson: RelationshipStatus._dateTimeFromTimestamp,
    toJson: RelationshipStatus._timestampFromDateTime,
  )
  final DateTime? lastMoodChange;

  EmotionalState({
    this.currentMood = 'neutral',
    this.energyLevel = 80,
    this.lastMoodChange,
  });

  factory EmotionalState.fromJson(Map<String, dynamic> json) =>
      _$EmotionalStateFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionalStateToJson(this);
}

@JsonSerializable()
class InteractionPatterns {
  final int totalGhostsDetected;
  final double averageResponseTime;
  final String chatFrequency;
  final String? lastGhostWarning;

  InteractionPatterns({
    this.totalGhostsDetected = 0,
    this.averageResponseTime = 0.0,
    this.chatFrequency = 'daily',
    this.lastGhostWarning,
  });

  factory InteractionPatterns.fromJson(Map<String, dynamic> json) =>
      _$InteractionPatternsFromJson(json);
  Map<String, dynamic> toJson() => _$InteractionPatternsToJson(this);
}

@JsonSerializable()
class CharacterMessage {
  final String id;
  final String characterId;
  final String userId;
  final String role;
  final String content;
  @JsonKey(
    fromJson: RelationshipStatus._dateTimeFromTimestamp,
    toJson: RelationshipStatus._timestampFromDateTime,
  )
  final DateTime? timestamp;
  @RelationshipStageConverter()
  final RelationshipStage relationshipStage;
  final String? imageUrl;

  CharacterMessage({
    this.id = '',
    this.characterId = '',
    this.userId = '',
    this.role = '',
    this.content = '',
    this.timestamp,
    this.relationshipStage = RelationshipStage.stranger,
    this.imageUrl,
  });

  factory CharacterMessage.fromJson(Map<String, dynamic> json) =>
      _$CharacterMessageFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterMessageToJson(this);
}
