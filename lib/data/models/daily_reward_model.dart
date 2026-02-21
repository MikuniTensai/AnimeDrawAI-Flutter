import 'package:json_annotation/json_annotation.dart';

part 'daily_reward_model.g.dart';

@JsonSerializable()
class DailyRewardConfig {
  final int day;
  final String type;
  final String id;
  final int amount;
  final String name;

  DailyRewardConfig({
    required this.day,
    required this.type,
    required this.id,
    required this.amount,
    required this.name,
  });

  factory DailyRewardConfig.fromJson(Map<String, dynamic> json) =>
      _$DailyRewardConfigFromJson(json);
  Map<String, dynamic> toJson() => _$DailyRewardConfigToJson(this);
}

@JsonSerializable()
class DailyStatusResponse {
  final bool success;
  @JsonKey(name: 'is_claimable')
  final bool isClaimable;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'last_claim_date')
  final String? lastClaimDate;
  @JsonKey(name: 'next_day_index')
  final int nextDayIndex;
  final DailyRewardConfig? reward;
  @JsonKey(name: 'reward_cycle')
  final String? rewardCycle;
  @JsonKey(name: 'streak_saved')
  final bool streakSaved;
  final String? error;

  DailyStatusResponse({
    required this.success,
    required this.isClaimable,
    required this.currentStreak,
    this.lastClaimDate,
    required this.nextDayIndex,
    this.reward,
    this.rewardCycle = 'A',
    this.streakSaved = false,
    this.error,
  });

  factory DailyStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DailyStatusResponseToJson(this);
}

@JsonSerializable()
class DailyClaimResponse {
  final bool success;
  final DailyRewardConfig? reward;
  @JsonKey(name: 'new_streak')
  final int newStreak;
  @JsonKey(name: 'streak_freeze_used')
  final bool streakFreezeUsed;
  final String? error;

  DailyClaimResponse({
    required this.success,
    this.reward,
    required this.newStreak,
    this.streakFreezeUsed = false,
    this.error,
  });

  factory DailyClaimResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyClaimResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DailyClaimResponseToJson(this);
}
