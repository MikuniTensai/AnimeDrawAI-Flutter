import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  Map<String, dynamic>? _arguments;

  int get currentIndex => _currentIndex;
  Map<String, dynamic>? get arguments => _arguments;

  void setIndex(int index, {Map<String, dynamic>? arguments}) {
    _currentIndex = index;
    _arguments = arguments;
    notifyListeners();
  }

  void clearArguments() {
    _arguments = null;
  }
}
