import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Math challenge dialog as an alternative age/human verification.
/// Equivalent to Android's MathChallengeDialog.
class MathChallengeDialog extends StatefulWidget {
  final void Function(bool passed) onResult;

  const MathChallengeDialog({super.key, required this.onResult});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MathChallengeDialog(
        onResult: (passed) => Navigator.of(ctx).pop(passed),
      ),
    );
  }

  @override
  State<MathChallengeDialog> createState() => _MathChallengeDialogState();
}

class _MathChallengeDialogState extends State<MathChallengeDialog> {
  final _answerController = TextEditingController();
  late int _num1;
  late int _num2;
  late String _operator;
  late int _correctAnswer;
  String? _error;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final random = Random();
    final ops = ['+', '-', '×'];
    _operator = ops[random.nextInt(ops.length)];

    switch (_operator) {
      case '+':
        _num1 = random.nextInt(50) + 1;
        _num2 = random.nextInt(50) + 1;
        _correctAnswer = _num1 + _num2;
        break;
      case '-':
        _num1 = random.nextInt(50) + 10;
        _num2 = random.nextInt(_num1) + 1;
        _correctAnswer = _num1 - _num2;
        break;
      case '×':
        _num1 = random.nextInt(10) + 2;
        _num2 = random.nextInt(10) + 2;
        _correctAnswer = _num1 * _num2;
        break;
      default:
        _num1 = 5;
        _num2 = 3;
        _correctAnswer = 8;
    }
  }

  void _verify() {
    final answer = int.tryParse(_answerController.text.trim());
    if (answer == null) {
      setState(() => _error = 'Please enter a number');
      return;
    }

    if (answer == _correctAnswer) {
      widget.onResult(true);
    } else {
      _attempts++;
      if (_attempts >= 3) {
        // Too many wrong attempts - regenerate
        setState(() {
          _error = 'Incorrect. New challenge generated!';
          _answerController.clear();
          _generateChallenge();
          _attempts = 0;
        });
      } else {
        setState(() {
          _error = 'Incorrect answer. Try again! ($_attempts/3)';
          _answerController.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(
            Icons.calculate_outlined,
            size: 48,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 8),
          Text(
            'Quick Math Check',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Solve this to continue:',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_num1 $_operator $_num2 = ?',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              hintText: 'Your answer',
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onResult(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
