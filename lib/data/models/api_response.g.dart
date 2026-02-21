// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiResponse<T>(
  success: json['success'] as bool,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  error: json['error'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$ApiResponseToJson<T>(
  ApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'error': instance.error,
  'message': instance.message,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

WorkflowInfo _$WorkflowInfoFromJson(Map<String, dynamic> json) => WorkflowInfo(
  name: json['name'] as String,
  description: json['description'] as String,
  estimatedTime: json['estimated_time'] as String,
  fileExists: json['file_exists'] as bool,
  isPremium: json['isPremium'] as bool? ?? false,
  restricted: json['restricted'] as bool? ?? false,
  useCount: (json['use_count'] as num?)?.toInt() ?? 0,
  viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
  category: json['category'] as String?,
);

Map<String, dynamic> _$WorkflowInfoToJson(WorkflowInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'estimated_time': instance.estimatedTime,
      'file_exists': instance.fileExists,
      'isPremium': instance.isPremium,
      'restricted': instance.restricted,
      'use_count': instance.useCount,
      'view_count': instance.viewCount,
      'category': instance.category,
    };

WorkflowsResponse _$WorkflowsResponseFromJson(Map<String, dynamic> json) =>
    WorkflowsResponse(
      success: json['success'] as bool,
      workflows: (json['workflows'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, WorkflowInfo.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$WorkflowsResponseToJson(WorkflowsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'workflows': instance.workflows,
    };
