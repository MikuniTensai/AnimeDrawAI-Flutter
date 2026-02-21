// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateRequest _$GenerateRequestFromJson(Map<String, dynamic> json) =>
    GenerateRequest(
      positivePrompt: json['positive_prompt'] as String,
      negativePrompt: json['negative_prompt'] as String? ?? '',
      workflow: json['workflow'] as String? ?? 'standard',
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      ckptName: json['ckpt_name'] as String?,
      steps: (json['steps'] as num?)?.toInt(),
      cfg: (json['cfg'] as num?)?.toDouble(),
      samplerName: json['sampler_name'] as String?,
      scheduler: json['scheduler'] as String?,
      denoise: (json['denoise'] as num?)?.toDouble(),
      upscaleMethod: json['upscale_method'] as String?,
    );

Map<String, dynamic> _$GenerateRequestToJson(GenerateRequest instance) =>
    <String, dynamic>{
      'positive_prompt': instance.positivePrompt,
      'negative_prompt': instance.negativePrompt,
      'workflow': instance.workflow,
      'width': instance.width,
      'height': instance.height,
      'seed': instance.seed,
      'ckpt_name': instance.ckptName,
      'steps': instance.steps,
      'cfg': instance.cfg,
      'sampler_name': instance.samplerName,
      'scheduler': instance.scheduler,
      'denoise': instance.denoise,
      'upscale_method': instance.upscaleMethod,
    };

LimitInfo _$LimitInfoFromJson(Map<String, dynamic> json) => LimitInfo(
  remaining: (json['remaining'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  message: json['message'] as String?,
);

Map<String, dynamic> _$LimitInfoToJson(LimitInfo instance) => <String, dynamic>{
  'remaining': instance.remaining,
  'total': instance.total,
  'message': instance.message,
};

GenerateResponse _$GenerateResponseFromJson(Map<String, dynamic> json) =>
    GenerateResponse(
      success: json['success'] as bool,
      taskId: json['task_id'] as String?,
      workflow: json['workflow'] as String?,
      workflowName: json['workflow_name'] as String?,
      estimatedTime: json['estimated_time'] as String?,
      status: json['status'] as String?,
      gemsEarned: (json['gems_earned'] as num?)?.toInt(),
      error: json['error'] as String?,
      limitInfo: json['limit_info'] == null
          ? null
          : LimitInfo.fromJson(json['limit_info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GenerateResponseToJson(GenerateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'task_id': instance.taskId,
      'workflow': instance.workflow,
      'workflow_name': instance.workflowName,
      'estimated_time': instance.estimatedTime,
      'status': instance.status,
      'gems_earned': instance.gemsEarned,
      'error': instance.error,
      'limit_info': instance.limitInfo,
    };

TaskStatusResponse _$TaskStatusResponseFromJson(Map<String, dynamic> json) =>
    TaskStatusResponse(
      success: json['success'] as bool,
      taskId: json['task_id'] as String,
      status: json['status'] as String,
      positivePrompt: json['positive_prompt'] as String?,
      negativePrompt: json['negative_prompt'] as String?,
      workflow: json['workflow'] as String?,
      workflowName: json['workflow_name'] as String?,
      createdAt: json['created_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      estimatedTime: json['estimated_time'] as String?,
      resultFiles: (json['result_files'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      downloadUrls: (json['download_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      queuePosition: (json['queue_position'] as num?)?.toInt(),
      queueTotal: (json['queue_total'] as num?)?.toInt(),
      queueInfo: json['queue_info'] as String?,
      progress: (json['progress'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$TaskStatusResponseToJson(TaskStatusResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'task_id': instance.taskId,
      'status': instance.status,
      'positive_prompt': instance.positivePrompt,
      'negative_prompt': instance.negativePrompt,
      'workflow': instance.workflow,
      'workflow_name': instance.workflowName,
      'created_at': instance.createdAt,
      'started_at': instance.startedAt,
      'completed_at': instance.completedAt,
      'estimated_time': instance.estimatedTime,
      'result_files': instance.resultFiles,
      'download_urls': instance.downloadUrls,
      'queue_position': instance.queuePosition,
      'queue_total': instance.queueTotal,
      'queue_info': instance.queueInfo,
      'progress': instance.progress,
      'seed': instance.seed,
      'error': instance.error,
    };
