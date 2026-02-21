// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String?,
  role: json['role'] as String,
  content: json['content'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'role': instance.role,
      'content': instance.content,
      'timestamp': instance.timestamp,
    };

ChatSendRequest _$ChatSendRequestFromJson(Map<String, dynamic> json) =>
    ChatSendRequest(
      message: json['message'] as String,
      sessionId: json['session_id'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      maxTokens: (json['max_tokens'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChatSendRequestToJson(ChatSendRequest instance) =>
    <String, dynamic>{
      'message': instance.message,
      'session_id': instance.sessionId,
      'temperature': instance.temperature,
      'max_tokens': instance.maxTokens,
    };

ChatSendResponse _$ChatSendResponseFromJson(Map<String, dynamic> json) =>
    ChatSendResponse(
      success: json['success'] as bool,
      sessionId: json['session_id'] as String?,
      response: json['response'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ChatSendResponseToJson(ChatSendResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'session_id': instance.sessionId,
      'response': instance.response,
      'error': instance.error,
    };
