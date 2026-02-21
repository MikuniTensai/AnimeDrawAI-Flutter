// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_limit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerationLimit _$GenerationLimitFromJson(Map<String, dynamic> json) =>
    GenerationLimit(
      userId: json['userId'] as String? ?? '',
      dailyGenerations: (json['dailyGenerations'] as num?)?.toInt() ?? 0,
      maxDailyLimit: (json['maxDailyLimit'] as num?)?.toInt() ?? freeDailyLimit,
      lastResetDate: json['lastResetDate'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
      totalGenerations: (json['totalGenerations'] as num?)?.toInt() ?? 0,
      subscriptionType: json['subscriptionType'] as String? ?? 'free',
      subscriptionUsed: (json['subscriptionUsed'] as num?)?.toInt() ?? 0,
      subscriptionLimit: (json['subscriptionLimit'] as num?)?.toInt() ?? 0,
      bonusGenerations: (json['bonusGenerations'] as num?)?.toInt() ?? 0,
      purchasedGenerations:
          (json['purchasedGenerations'] as num?)?.toInt() ?? 0,
      moreEnabled: json['moreEnabled'] as bool? ?? false,
      moreRequestStatus: json['moreRequestStatus'] as String? ?? '',
      subscriptionEndDate: GenerationLimit._dateTimeFromTimestamp(
        json['subscriptionEndDate'],
      ),
      createdAt: GenerationLimit._dateTimeFromTimestamp(json['createdAt']),
      updatedAt: GenerationLimit._dateTimeFromTimestamp(json['updatedAt']),
    );

Map<String, dynamic> _$GenerationLimitToJson(GenerationLimit instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'dailyGenerations': instance.dailyGenerations,
      'maxDailyLimit': instance.maxDailyLimit,
      'lastResetDate': instance.lastResetDate,
      'isPremium': instance.isPremium,
      'totalGenerations': instance.totalGenerations,
      'subscriptionType': instance.subscriptionType,
      'subscriptionUsed': instance.subscriptionUsed,
      'subscriptionLimit': instance.subscriptionLimit,
      'bonusGenerations': instance.bonusGenerations,
      'purchasedGenerations': instance.purchasedGenerations,
      'moreEnabled': instance.moreEnabled,
      'moreRequestStatus': instance.moreRequestStatus,
      'subscriptionEndDate': GenerationLimit._dateTimeToTimestamp(
        instance.subscriptionEndDate,
      ),
      'createdAt': GenerationLimit._dateTimeToTimestamp(instance.createdAt),
      'updatedAt': GenerationLimit._dateTimeToTimestamp(instance.updatedAt),
    };
