import 'package:flutter/foundation.dart';
import '../repositories/drawai_repository.dart';
import '../models/shop_model.dart';

abstract class InventoryUiState {}

class InventoryLoading extends InventoryUiState {}

class InventorySuccess extends InventoryUiState {
  final List<InventoryItemModel> items;
  InventorySuccess(this.items);
}

class InventoryError extends InventoryUiState {
  final String message;
  InventoryError(this.message);
}

class InventoryProvider extends ChangeNotifier {
  final DrawAiRepository _repository;

  InventoryProvider(this._repository) {
    loadInventory();
  }

  InventoryUiState _state = InventoryLoading();
  InventoryUiState get state => _state;

  Future<void> loadInventory({bool forceRefresh = false}) async {
    _state = InventoryLoading();
    notifyListeners();

    try {
      final items = await _repository.getInventory(forceRefresh: forceRefresh);
      _state = InventorySuccess(items);
    } catch (e) {
      _state = InventoryError(e.toString());
    }
    notifyListeners();
  }

  Future<void> refresh() => loadInventory(forceRefresh: true);
}
