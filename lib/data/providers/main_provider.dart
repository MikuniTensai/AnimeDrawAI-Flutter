import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/generation_repository.dart';

class MainProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final GenerationRepository _generationRepository;

  MainProvider(this._authRepository, this._generationRepository) {
    _init();
  }

  dynamic _generationLimit;
  dynamic get generationLimit => _generationLimit;

  String? _currentUserId;
  StreamSubscription? _authSubscription;
  StreamSubscription? _subscriptionListener;

  void _init() {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      final newUserId = user?.uid;
      if (newUserId != _currentUserId) {
        _handleUserChange(newUserId);
      }
    });
  }

  void _handleUserChange(String? newUserId) {
    _subscriptionListener?.cancel();
    _generationLimit = null;
    _currentUserId = newUserId;
    notifyListeners();

    if (newUserId != null) {
      _syncSubscriptionStatus(newUserId);
    }
  }

  void _syncSubscriptionStatus(String userId) {
    _subscriptionListener = _generationRepository
        .getGenerationLimitStream(userId)
        .listen((limit) {
          _generationLimit = limit;
          notifyListeners();
        }, onError: (e) => debugPrint('Error syncing subscription: $e'));
  }

  bool get isPremium {
    if (_generationLimit == null) return false;
    try {
      return _generationLimit.isPremium == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _subscriptionListener?.cancel();
    super.dispose();
  }
}
