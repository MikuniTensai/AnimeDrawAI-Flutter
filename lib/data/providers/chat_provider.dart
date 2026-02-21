import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;

  ChatProvider(this._repository) {
    _createNewSession();
  }

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  String _selectedModel = 'gemma3:4b';
  String get selectedModel => _selectedModel;

  String _getSafeErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('Unable to resolve host') ||
        msg.contains('SocketException')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    if (msg.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    }
    return msg;
  }

  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;

    _isSending = true;
    _error = null;
    notifyListeners();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = ChatMessage(
      id: tempId,
      sessionId: _currentSessionId,
      role: 'user',
      content: messageText,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _messages = [..._messages, userMessage];
    notifyListeners();

    try {
      final response = await _repository.sendGeneralMessage(
        messageText,
        _currentSessionId,
      );

      if (response != null) {
        if (response.sessionId != null) {
          _currentSessionId = response.sessionId;
        }
        _messages = [..._messages, response];
      }
    } catch (e) {
      _error = _getSafeErrorMessage(e);
      _messages = _messages.where((m) => m.id != tempId).toList();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final historyMessages = await _repository.getHistory(sessionId);
      _messages = historyMessages;
      _currentSessionId = sessionId;
    } catch (e) {
      _error = _getSafeErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createNewSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sessionId = await _repository.createSession();
      _currentSessionId = sessionId;
      _messages = [];
    } catch (e) {
      _error = _getSafeErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    if (_currentSessionId == null) return;
    try {
      await _repository.deleteSession(_currentSessionId!);
      await _createNewSession();
    } catch (e) {
      _error = _getSafeErrorMessage(e);
      notifyListeners();
    }
  }

  void selectModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
