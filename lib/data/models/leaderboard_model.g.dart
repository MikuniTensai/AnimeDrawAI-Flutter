// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhoto: json['userPhoto'] as String?,
      score: (json['score'] as num).toDouble(),
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhoto': instance.userPhoto,
      'score': instance.score,
    };

LeaderboardData _$LeaderboardDataFromJson(Map<String, dynamic> json) =>
    LeaderboardData(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updatedAt'],
    );

Map<String, dynamic> _$LeaderboardDataToJson(LeaderboardData instance) =>
    <String, dynamic>{
      'entries': instance.entries,
      'updatedAt': instance.updatedAt,
    };
