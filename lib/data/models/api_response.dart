import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  ApiResponse({required this.success, this.data, this.error, this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

@JsonSerializable()
class WorkflowInfo {
  final String name;
  final String description;
  @JsonKey(name: 'estimated_time')
  final String estimatedTime;
  @JsonKey(name: 'file_exists')
  final bool fileExists;
  final bool isPremium;
  final bool restricted;
  @JsonKey(name: 'use_count', defaultValue: 0)
  final int useCount;
  @JsonKey(name: 'view_count', defaultValue: 0)
  final int viewCount;

  final String? category;

  WorkflowInfo({
    required this.name,
    required this.description,
    required this.estimatedTime,
    required this.fileExists,
    this.isPremium = false,
    this.restricted = false,
    this.useCount = 0,
    this.viewCount = 0,
    this.category,
  });

  factory WorkflowInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkflowInfoFromJson(json);
  Map<String, dynamic> toJson() => _$WorkflowInfoToJson(this);
}

@JsonSerializable()
class WorkflowsResponse {
  final bool success;
  final Map<String, WorkflowInfo> workflows;

  WorkflowsResponse({required this.success, required this.workflows});

  factory WorkflowsResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkflowsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkflowsResponseToJson(this);
}
