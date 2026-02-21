import 'package:json_annotation/json_annotation.dart';

part 'generation_model.g.dart';

@JsonSerializable()
class GenerateRequest {
  @JsonKey(name: 'positive_prompt')
  final String positivePrompt;
  @JsonKey(name: 'negative_prompt')
  final String negativePrompt;
  final String workflow;
  final int? width;
  final int? height;
  final int? seed;
  @JsonKey(name: 'ckpt_name')
  final String? ckptName;
  final int? steps;
  final double? cfg;
  @JsonKey(name: 'sampler_name')
  final String? samplerName;
  final String? scheduler;
  final double? denoise;
  @JsonKey(name: 'upscale_method')
  final String? upscaleMethod;

  GenerateRequest({
    required this.positivePrompt,
    this.negativePrompt = '',
    this.workflow = 'standard',
    this.width,
    this.height,
    this.seed,
    this.ckptName,
    this.steps,
    this.cfg,
    this.samplerName,
    this.scheduler,
    this.denoise,
    this.upscaleMethod,
  });

  factory GenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateRequestToJson(this);
}

@JsonSerializable()
class LimitInfo {
  final int remaining;
  final int total;
  final String? message;

  LimitInfo({required this.remaining, required this.total, this.message});

  factory LimitInfo.fromJson(Map<String, dynamic> json) =>
      _$LimitInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LimitInfoToJson(this);
}

@JsonSerializable()
class GenerateResponse {
  final bool success;
  @JsonKey(name: 'task_id')
  final String? taskId;
  final String? workflow;
  @JsonKey(name: 'workflow_name')
  final String? workflowName;
  @JsonKey(name: 'estimated_time')
  final String? estimatedTime;
  final String? status;
  @JsonKey(name: 'gems_earned')
  final int? gemsEarned;
  final String? error;

  @JsonKey(name: 'limit_info')
  final LimitInfo? limitInfo;

  GenerateResponse({
    required this.success,
    this.taskId,
    this.workflow,
    this.workflowName,
    this.estimatedTime,
    this.status,
    this.gemsEarned,
    this.error,
    this.limitInfo,
  });

  factory GenerateResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateResponseToJson(this);
}

@JsonSerializable()
class TaskStatusResponse {
  final bool success;
  @JsonKey(name: 'task_id')
  final String taskId;
  final String status;
  @JsonKey(name: 'positive_prompt')
  final String? positivePrompt;
  @JsonKey(name: 'negative_prompt')
  final String? negativePrompt;
  final String? workflow;
  @JsonKey(name: 'workflow_name')
  final String? workflowName;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'started_at')
  final String? startedAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'estimated_time')
  final String? estimatedTime;
  @JsonKey(name: 'result_files')
  final List<String>? resultFiles;
  @JsonKey(name: 'download_urls')
  final List<String>? downloadUrls;
  @JsonKey(name: 'queue_position')
  final int? queuePosition;
  @JsonKey(name: 'queue_total')
  final int? queueTotal;
  @JsonKey(name: 'queue_info')
  final String? queueInfo;
  final int? progress;
  final int? seed;
  final String? error;

  TaskStatusResponse({
    required this.success,
    required this.taskId,
    required this.status,
    this.positivePrompt,
    this.negativePrompt,
    this.workflow,
    this.workflowName,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.estimatedTime,
    this.resultFiles,
    this.downloadUrls,
    this.queuePosition,
    this.queueTotal,
    this.queueInfo,
    this.progress,
    this.seed,
    this.error,
  });

  factory TaskStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TaskStatusResponseToJson(this);
}
