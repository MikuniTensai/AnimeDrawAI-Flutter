import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_model.g.dart';

@JsonSerializable()
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userPhoto;
  final double score;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.score,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);

  factory LeaderboardEntry.fromFirestore(Map<String, dynamic> data) {
    return LeaderboardEntry(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhoto: data['userPhoto'],
      score: (data['score'] ?? 0).toDouble(),
    );
  }
}

@JsonSerializable()
class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final dynamic updatedAt;

  LeaderboardData({required this.entries, this.updatedAt});

  factory LeaderboardData.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardDataToJson(this);

  factory LeaderboardData.fromFirestore(Map<String, dynamic> data) {
    return LeaderboardData(
      entries: (data['entries'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      updatedAt: data['updatedAt'],
    );
  }
}
