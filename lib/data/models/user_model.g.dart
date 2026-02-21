// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String?,
  apiKey: json['apiKey'] as String,
  isGuest: json['isGuest'] as bool? ?? false,
  isPremium: json['isPremium'] as bool? ?? false,
  subscriptionEndDate: (json['subscriptionEndDate'] as num?)?.toInt(),
  gems: (json['gems'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'apiKey': instance.apiKey,
  'isGuest': instance.isGuest,
  'isPremium': instance.isPremium,
  'subscriptionEndDate': instance.subscriptionEndDate,
  'gems': instance.gems,
};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    LoginRequest(apiKey: json['apiKey'] as String);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'apiKey': instance.apiKey};

ApiKeyResponse _$ApiKeyResponseFromJson(Map<String, dynamic> json) =>
    ApiKeyResponse(
      success: json['success'] as bool,
      apiKey: json['api_key'] as String,
      name: json['name'] as String,
      rateLimit: json['rate_limit'] as String,
      note: json['note'] as String,
    );

Map<String, dynamic> _$ApiKeyResponseToJson(ApiKeyResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'api_key': instance.apiKey,
      'name': instance.name,
      'rate_limit': instance.rateLimit,
      'note': instance.note,
    };
