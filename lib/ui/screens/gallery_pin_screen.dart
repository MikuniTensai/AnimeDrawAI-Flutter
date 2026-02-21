import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/user_preferences.dart';

/// PIN lock screen for Gallery access.
/// Equivalent to Android's GalleryPinScreen.
class GalleryPinScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const GalleryPinScreen({super.key, required this.onSuccess, this.onCancel});

  @override
  State<GalleryPinScreen> createState() => _GalleryPinScreenState();
}

class _GalleryPinScreenState extends State<GalleryPinScreen>
    with SingleTickerProviderStateMixin {
  final _prefs = UserPreferences();
  final List<String> _enteredPin = [];
  static const int _pinLength = 4;
  int _failedAttempts = 0;
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (_enteredPin.length >= _pinLength) return;
    setState(() {
      _enteredPin.add(key);
      _isError = false;
    });
    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin.removeLast();
      _isError = false;
    });
  }

  Future<void> _verifyPin() async {
    final pin = _enteredPin.join();
    final isCorrect = await _prefs.verifyGalleryPin(pin);
    if (isCorrect) {
      HapticFeedback.lightImpact();
      widget.onSuccess();
    } else {
      _failedAttempts++;
      HapticFeedback.heavyImpact();
      setState(() {
        _isError = true;
        _enteredPin.clear();
      });
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onCancel != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onCancel,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'Enter Gallery PIN',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_failedAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Incorrect PIN. Attempt $_failedAttempts',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 32),
            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = _isError
                    ? 10 * (0.5 - (_shakeAnimation.value % 1)).abs()
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset * 20, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? theme.colorScheme.error
                          : filled
                          ? theme.colorScheme.primary
                          : Colors.white24,
                      border: Border.all(
                        color: _isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 40),
            // Numpad
            _buildNumpad(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'del'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 72, height: 72);
                if (key == 'del') {
                  return _NumpadButton(
                    onTap: _onDelete,
                    child: const Icon(Icons.backspace_outlined),
                  );
                }
                return _NumpadButton(
                  onTap: () => _onKeyPressed(key),
                  child: Text(
                    key,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NumpadButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white10,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
