// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSubscription _$UserSubscriptionFromJson(Map<String, dynamic> json) =>
    UserSubscription(
      plan:
          $enumDecodeNullable(_$SubscriptionPlanEnumMap, json['plan']) ??
          SubscriptionPlan.free,
      generationUsed: (json['generationUsed'] as num?)?.toInt() ?? 0,
      dailyGenerationCount:
          (json['dailyGenerationCount'] as num?)?.toInt() ?? 0,
      lastGenerationDate: json['lastGenerationDate'] as String? ?? '',
      subscriptionStartDate: json['subscriptionStartDate'] as String? ?? '',
      expiryDate: json['expiryDate'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      moreAccess: json['moreAccess'] as bool? ?? false,
    );

Map<String, dynamic> _$UserSubscriptionToJson(UserSubscription instance) =>
    <String, dynamic>{
      'plan': _$SubscriptionPlanEnumMap[instance.plan]!,
      'generationUsed': instance.generationUsed,
      'dailyGenerationCount': instance.dailyGenerationCount,
      'lastGenerationDate': instance.lastGenerationDate,
      'subscriptionStartDate': instance.subscriptionStartDate,
      'expiryDate': instance.expiryDate,
      'isActive': instance.isActive,
      'moreAccess': instance.moreAccess,
    };

const _$SubscriptionPlanEnumMap = {
  SubscriptionPlan.free: 'FREE',
  SubscriptionPlan.basic: 'BASIC',
  SubscriptionPlan.pro: 'PRO',
};
