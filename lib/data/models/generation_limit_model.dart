import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'generation_limit_model.g.dart';

const int freeDailyLimit = 5;
const int basicLimit = 50;
const int proLimit = 1000;
const int freeChatLimit = 10;
const int basicChatLimit = 100;
const int proChatLimit = 1000;
const int subscriptionDays = 30;

@JsonSerializable()
class GenerationLimit {
  final String userId;
  final int dailyGenerations;
  final int maxDailyLimit;
  final String lastResetDate;
  final bool isPremium;
  final int totalGenerations;
  final String subscriptionType; // "free", "basic", "pro"
  final int subscriptionUsed;
  final int subscriptionLimit;
  final int bonusGenerations;
  final int purchasedGenerations;
  final bool moreEnabled;
  final String moreRequestStatus; // "none", "pending", "approved", "rejected"

  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime? subscriptionEndDate;

  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime? createdAt;

  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime? updatedAt;

  GenerationLimit({
    this.userId = '',
    this.dailyGenerations = 0,
    this.maxDailyLimit = freeDailyLimit,
    this.lastResetDate = '',
    this.isPremium = false,
    this.totalGenerations = 0,
    this.subscriptionType = 'free',
    this.subscriptionUsed = 0,
    this.subscriptionLimit = 0,
    this.bonusGenerations = 0,
    this.purchasedGenerations = 0,
    this.moreEnabled = false,
    this.moreRequestStatus = '',
    this.subscriptionEndDate,
    this.createdAt,
    this.updatedAt,
  });

  factory GenerationLimit.fromJson(Map<String, dynamic> json) =>
      _$GenerationLimitFromJson(json);
  Map<String, dynamic> toJson() => _$GenerationLimitToJson(this);

  static DateTime? _dateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }

  static dynamic _dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  bool canGenerate() {
    if (subscriptionType != 'free') {
      final effectiveLimit = subscriptionLimit > 0
          ? subscriptionLimit
          : (subscriptionType == 'pro' ? 600 : 200);
      return subscriptionUsed < effectiveLimit;
    }
    return dailyGenerations <
        (maxDailyLimit + bonusGenerations + purchasedGenerations);
  }

  int getRemainingGenerations() {
    if (subscriptionType != 'free') {
      final effectiveLimit = subscriptionLimit > 0
          ? subscriptionLimit
          : (subscriptionType == 'pro' ? 600 : 200);
      return effectiveLimit - subscriptionUsed;
    }
    return (maxDailyLimit + bonusGenerations + purchasedGenerations) -
        dailyGenerations;
  }

  int getMaxGenerations() {
    if (subscriptionType != 'free') {
      return subscriptionLimit > 0
          ? subscriptionLimit
          : (subscriptionType == 'pro' ? 600 : 200);
    }
    return maxDailyLimit + bonusGenerations + purchasedGenerations;
  }

  int get maxChatLimit {
    switch (subscriptionType) {
      case 'pro':
        return proChatLimit;
      case 'basic':
        return basicChatLimit;
      default:
        return freeChatLimit;
    }
  }

  bool needsReset(String currentDate) {
    return lastResetDate != currentDate;
  }

  GenerationLimit copyWith({
    String? userId,
    int? dailyGenerations,
    int? maxDailyLimit,
    String? lastResetDate,
    bool? isPremium,
    int? totalGenerations,
    String? subscriptionType,
    int? subscriptionUsed,
    int? subscriptionLimit,
    int? bonusGenerations,
    int? purchasedGenerations,
    bool? moreEnabled,
    String? moreRequestStatus,
    DateTime? subscriptionEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GenerationLimit(
      userId: userId ?? this.userId,
      dailyGenerations: dailyGenerations ?? this.dailyGenerations,
      maxDailyLimit: maxDailyLimit ?? this.maxDailyLimit,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      isPremium: isPremium ?? this.isPremium,
      totalGenerations: totalGenerations ?? this.totalGenerations,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionUsed: subscriptionUsed ?? this.subscriptionUsed,
      subscriptionLimit: subscriptionLimit ?? this.subscriptionLimit,
      bonusGenerations: bonusGenerations ?? this.bonusGenerations,
      purchasedGenerations: purchasedGenerations ?? this.purchasedGenerations,
      moreEnabled: moreEnabled ?? this.moreEnabled,
      moreRequestStatus: moreRequestStatus ?? this.moreRequestStatus,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
