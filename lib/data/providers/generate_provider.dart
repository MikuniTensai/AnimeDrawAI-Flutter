import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/drawai_repository.dart';
import '../repositories/workflow_stats_repository.dart';
import '../repositories/auth_repository.dart';

// ─── UI States ───────────────────────────────────────────────────────────────

abstract class GenerateUiState {
  const GenerateUiState();
}

class GenerateIdle extends GenerateUiState {
  const GenerateIdle();
}

class GenerateLoading extends GenerateUiState {
  final String message;
  const GenerateLoading(this.message);
}

class GenerateProcessing extends GenerateUiState {
  final String message;
  const GenerateProcessing(this.message);
}

class GenerateSuccess extends GenerateUiState {
  final dynamic result;
  const GenerateSuccess(this.result);
}

class GenerateError extends GenerateUiState {
  final String message;
  const GenerateError(this.message);
}

class GenerateLimitExceeded extends GenerateUiState {
  final String message;
  final int remaining;
  const GenerateLimitExceeded({required this.message, this.remaining = 0});
}

class GenerateContentModeration extends GenerateUiState {
  final String message;
  final List<String> inappropriateWords;
  const GenerateContentModeration({
    required this.message,
    this.inappropriateWords = const [],
  });
}

// ─── Inappropriate word list (ported from Android) ───────────────────────────

const _inappropriateWords = {
  'bugil',
  'telanjang',
  'porno',
  'seks',
  'vulgar',
  'cabul',
  'mesum',
  'asusila',
  'erotis',
  'sensual',
  'birahi',
  'nafsu',
  'syahwat',
  'lonte',
  'pelacur',
  'jablay',
  'bokep',
  'ngentot',
  'memek',
  'kontol',
  'ngewe',
  'jembut',
  'itil',
  'toket',
  'pentil',
  'perek',
  'germo',
  'sundal',
  'vagina',
  'pussy',
  'cunt',
  'penis',
  'cock',
  'dick',
  'fuck',
  'shit',
  'bitch',
  'bastard',
  'hentai',
  'nsfw',
  'explicit',
  'xxx',
  'hardcore',
  'undress',
  'nude',
  'naked',
  'porn',
  'adult',
  'mature',
};

// ─── Provider ─────────────────────────────────────────────────────────────────

class GenerateProvider extends ChangeNotifier {
  final DrawAiRepository _drawAiRepository;
  final AuthRepository _authRepository;
  final WorkflowStatsRepository _workflowStatsRepository;

  GenerateProvider(
    this._drawAiRepository,
    this._authRepository,
    this._workflowStatsRepository,
  ) {
    _init();
  }

  GenerateUiState _uiState = const GenerateIdle();
  GenerateUiState get uiState => _uiState;

  Map<String, dynamic> _workflows = {};
  Map<String, dynamic> get workflows => _workflows;

  Map<String, Map<String, int>> _workflowStats = {};
  Map<String, Map<String, int>> get workflowStats => _workflowStats;

  dynamic _generationLimit;
  dynamic get generationLimit => _generationLimit;

  int _gemCount = 0;
  int get gemCount => _gemCount;

  dynamic _dailyStatus;
  dynamic get dailyStatus => _dailyStatus;

  StreamSubscription? _gemCountSubscription;

  void _init() {
    loadWorkflows();
    loadWorkflowStats();
    _listenGemCount();
  }

  void _listenGemCount() {
    final user = _authRepository.currentUser;
    if (user == null) return;
    _gemCountSubscription?.cancel();
    _gemCountSubscription = _drawAiRepository
        .getGemCountStream(user.uid)
        .listen((count) {
          _gemCount = count;
          notifyListeners();
        });
  }

  void _setState(GenerateUiState state) {
    _uiState = state;
    notifyListeners();
  }

  Future<void> loadWorkflows() async {
    if (_workflows.isEmpty) {
      _setState(const GenerateLoading('Memuat workflows...'));
    }
    try {
      final result = await _drawAiRepository.getWorkflows();
      _workflows = result;
      if (_uiState is GenerateLoading) {
        _setState(const GenerateIdle());
      }
    } catch (e) {
      _setState(GenerateError(e.toString()));
    }
  }

  Future<void> loadGenerationLimit() async {
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      _generationLimit = await _drawAiRepository.getLimitStream(user.uid).first;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load generation limit: $e');
    }
  }

  Future<void> loadWorkflowStats() async {
    try {
      final stats = await _workflowStatsRepository.getAllStats();
      _workflowStats = stats.map(
        (k, v) => MapEntry(k, Map<String, int>.from(v)),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load workflow stats: $e');
    }
  }

  Future<void> incrementWorkflowView(String workflowId) async {
    try {
      await _workflowStatsRepository.incrementView(workflowId);
      await loadWorkflowStats();
    } catch (e) {
      debugPrint('Failed to increment workflow view: $e');
    }
  }

  Future<void> checkDailyStatus() async {
    try {
      _dailyStatus = await _drawAiRepository.checkDailyStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to check daily status: $e');
    }
  }

  Future<void> claimDailyReward() async {
    try {
      await _drawAiRepository.claimDailyReward();
      await checkDailyStatus();
    } catch (e) {
      debugPrint('Failed to claim daily reward: $e');
    }
  }

  /// Check if prompt contains inappropriate words
  (bool, List<String>) checkPromptInappropriate(String prompt) {
    final words = prompt.toLowerCase().split(RegExp(r'[\s,;.!?\n\t]+'));
    final found = <String>[];
    for (final bad in _inappropriateWords) {
      if (words.any((w) => w == bad || w.contains(bad))) {
        found.add(bad);
      }
    }
    return (found.isNotEmpty, found.toSet().toList());
  }

  Future<void> generateImage({
    required String positivePrompt,
    required String negativePrompt,
    required String workflow,
    int? seed,
  }) async {
    if (positivePrompt.trim().isEmpty) {
      _setState(const GenerateError('Prompt cannot be empty'));
      return;
    }

    // Content moderation
    final (hasInappropriate, foundWords) = checkPromptInappropriate(
      positivePrompt,
    );
    if (hasInappropriate) {
      _setState(
        GenerateContentModeration(
          message:
              'Prompt contains inappropriate content. Please revise your prompt.',
          inappropriateWords: foundWords,
        ),
      );
      return;
    }

    final user = _authRepository.currentUser;
    if (user == null) {
      _setState(const GenerateError('User not authenticated'));
      return;
    }

    try {
      _setState(const GenerateLoading('Queuing generation...'));

      final result = await _drawAiRepository.generateAndWait(
        positivePrompt: positivePrompt,
        negativePrompt: negativePrompt,
        workflow: workflow,
        userId: user.uid,
        seed: seed,
        onStatusUpdate: (status, _) {
          _setState(GenerateProcessing(status));
        },
      );

      // Increment workflow generation count and refresh stats
      try {
        await _workflowStatsRepository.incrementGeneration(workflow);
        loadWorkflowStats(); // Fire and forget reload (or await if critical)
      } catch (e) {
        debugPrint("Failed to increment generation stats: $e");
      }

      await loadGenerationLimit();
      _setState(GenerateSuccess(result));
    } on GenerationLimitExceededException catch (e) {
      _setState(
        GenerateLimitExceeded(message: e.message, remaining: e.remaining),
      );
    } catch (e) {
      _setState(GenerateError(e.toString()));
    }
  }

  void resetState() => _setState(const GenerateIdle());

  @override
  void dispose() {
    _gemCountSubscription?.cancel();
    super.dispose();
  }
}
