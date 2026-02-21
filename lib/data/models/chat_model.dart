import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class ChatMessage {
  final String id;
  final String? sessionId;
  final String role;
  final String content;
  final int timestamp;

  ChatMessage({
    required this.id,
    this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class ChatSendRequest {
  final String message;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  final double? temperature;
  @JsonKey(name: 'max_tokens')
  final int? maxTokens;

  ChatSendRequest({
    required this.message,
    this.sessionId,
    this.temperature,
    this.maxTokens,
  });

  factory ChatSendRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatSendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSendRequestToJson(this);
}

@JsonSerializable()
class ChatSendResponse {
  final bool success;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  final String? response;
  final String? error;

  ChatSendResponse({
    required this.success,
    this.sessionId,
    this.response,
    this.error,
  });

  factory ChatSendResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatSendResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSendResponseToJson(this);
}
