import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Age verification dialog that asks the user for their date of birth.
/// Equivalent to Android's AgeVerificationDialog.
class AgeVerificationDialog extends StatefulWidget {
  final void Function(bool isAdult) onResult;

  const AgeVerificationDialog({super.key, required this.onResult});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AgeVerificationDialog(
        onResult: (isAdult) => Navigator.of(ctx).pop(isAdult),
      ),
    );
  }

  @override
  State<AgeVerificationDialog> createState() => _AgeVerificationDialogState();
}

class _AgeVerificationDialogState extends State<AgeVerificationDialog> {
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _verify() {
    final day = int.tryParse(_dayController.text.trim());
    final month = int.tryParse(_monthController.text.trim());
    final year = int.tryParse(_yearController.text.trim());

    if (day == null || month == null || year == null) {
      setState(() => _error = 'Please enter a valid date');
      return;
    }

    try {
      final dob = DateTime(year, month, day);
      final now = DateTime.now();
      final age =
          now.year -
          dob.year -
          (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)
              ? 1
              : 0);

      if (age < 0 || dob.isAfter(now)) {
        setState(() => _error = 'Invalid date of birth');
        return;
      }

      widget.onResult(age >= 18);
    } catch (_) {
      setState(() => _error = 'Invalid date of birth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.cake_outlined, size: 48, color: Colors.pinkAccent),
          const SizedBox(height: 8),
          Text(
            'Age Verification',
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
            'Please enter your date of birth to continue.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _DateField(controller: _dayController, hint: 'DD', maxLength: 2),
              const SizedBox(width: 8),
              _DateField(
                controller: _monthController,
                hint: 'MM',
                maxLength: 2,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _DateField(
                  controller: _yearController,
                  hint: 'YYYY',
                  maxLength: 4,
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
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
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;

  const _DateField({
    required this.controller,
    required this.hint,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLength,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
