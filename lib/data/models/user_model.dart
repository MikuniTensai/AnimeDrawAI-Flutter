import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String? email;
  final String apiKey;
  final bool isGuest;
  final bool isPremium;
  final int? subscriptionEndDate; // Unix timestamp in milliseconds
  final int gems;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.apiKey,
    this.isGuest = false,
    this.isPremium = false,
    this.subscriptionEndDate,
    this.gems = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String apiKey;

  LoginRequest({required this.apiKey});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class ApiKeyResponse {
  final bool success;
  @JsonKey(name: 'api_key')
  final String apiKey;
  final String name;
  @JsonKey(name: 'rate_limit')
  final String rateLimit;
  final String note;

  ApiKeyResponse({
    required this.success,
    required this.apiKey,
    required this.name,
    required this.rateLimit,
    required this.note,
  });

  factory ApiKeyResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiKeyResponseToJson(this);
}
