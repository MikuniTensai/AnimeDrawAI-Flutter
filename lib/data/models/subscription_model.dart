import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

enum SubscriptionPlan {
  @JsonValue('FREE')
  free,
  @JsonValue('BASIC')
  basic,
  @JsonValue('PRO')
  pro,
}

@JsonSerializable()
class UserSubscription {
  final SubscriptionPlan plan;
  final int generationUsed;
  final int dailyGenerationCount;
  final String lastGenerationDate;
  final String subscriptionStartDate;
  final String? expiryDate;
  final bool isActive;
  final bool moreAccess;

  UserSubscription({
    this.plan = SubscriptionPlan.free,
    this.generationUsed = 0,
    this.dailyGenerationCount = 0,
    this.lastGenerationDate = '',
    this.subscriptionStartDate = '',
    this.expiryDate,
    this.isActive = true,
    this.moreAccess = false,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);
  Map<String, dynamic> toJson() => _$UserSubscriptionToJson(this);

  bool canGenerate() {
    if (plan == SubscriptionPlan.pro) return true;
    if (plan == SubscriptionPlan.basic) return generationUsed < 50;
    return dailyGenerationCount < 5; // Simplified free limit
  }

  UserSubscription copyWith({
    SubscriptionPlan? plan,
    int? generationUsed,
    int? dailyGenerationCount,
    String? lastGenerationDate,
    String? subscriptionStartDate,
    String? expiryDate,
    bool? isActive,
    bool? moreAccess,
  }) {
    return UserSubscription(
      plan: plan ?? this.plan,
      generationUsed: generationUsed ?? this.generationUsed,
      dailyGenerationCount: dailyGenerationCount ?? this.dailyGenerationCount,
      lastGenerationDate: lastGenerationDate ?? this.lastGenerationDate,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      moreAccess: moreAccess ?? this.moreAccess,
    );
  }
}
