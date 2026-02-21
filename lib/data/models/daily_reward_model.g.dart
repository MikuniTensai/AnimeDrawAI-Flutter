// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reward_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyRewardConfig _$DailyRewardConfigFromJson(Map<String, dynamic> json) =>
    DailyRewardConfig(
      day: (json['day'] as num).toInt(),
      type: json['type'] as String,
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$DailyRewardConfigToJson(DailyRewardConfig instance) =>
    <String, dynamic>{
      'day': instance.day,
      'type': instance.type,
      'id': instance.id,
      'amount': instance.amount,
      'name': instance.name,
    };

DailyStatusResponse _$DailyStatusResponseFromJson(Map<String, dynamic> json) =>
    DailyStatusResponse(
      success: json['success'] as bool,
      isClaimable: json['is_claimable'] as bool,
      currentStreak: (json['current_streak'] as num).toInt(),
      lastClaimDate: json['last_claim_date'] as String?,
      nextDayIndex: (json['next_day_index'] as num).toInt(),
      reward: json['reward'] == null
          ? null
          : DailyRewardConfig.fromJson(json['reward'] as Map<String, dynamic>),
      rewardCycle: json['reward_cycle'] as String? ?? 'A',
      streakSaved: json['streak_saved'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DailyStatusResponseToJson(
  DailyStatusResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'is_claimable': instance.isClaimable,
  'current_streak': instance.currentStreak,
  'last_claim_date': instance.lastClaimDate,
  'next_day_index': instance.nextDayIndex,
  'reward': instance.reward,
  'reward_cycle': instance.rewardCycle,
  'streak_saved': instance.streakSaved,
  'error': instance.error,
};

DailyClaimResponse _$DailyClaimResponseFromJson(Map<String, dynamic> json) =>
    DailyClaimResponse(
      success: json['success'] as bool,
      reward: json['reward'] == null
          ? null
          : DailyRewardConfig.fromJson(json['reward'] as Map<String, dynamic>),
      newStreak: (json['new_streak'] as num).toInt(),
      streakFreezeUsed: json['streak_freeze_used'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DailyClaimResponseToJson(DailyClaimResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'reward': instance.reward,
      'new_streak': instance.newStreak,
      'streak_freeze_used': instance.streakFreezeUsed,
      'error': instance.error,
    };
