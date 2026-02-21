import 'package:flutter/material.dart';

class PhotoRequestDialog extends StatefulWidget {
  final Function(String prompt, bool isCustom) onRequest;

  const PhotoRequestDialog({super.key, required this.onRequest});

  @override
  State<PhotoRequestDialog> createState() => _PhotoRequestDialogState();
}

class _PhotoRequestDialogState extends State<PhotoRequestDialog> {
  final TextEditingController _promptController = TextEditingController();
  bool _isCustom = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Request a Photo",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "How would you like to request a photo?",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Auto Request"),
              subtitle: const Text(
                "Let the AI decide the photo content based on context.",
              ),
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: !_isCustom
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: !_isCustom
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              onTap: () => setState(() => _isCustom = false),
            ),
            ListTile(
              title: const Text("Custom Request"),
              subtitle: const Text("Describe exactly what you want to see."),
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isCustom
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: _isCustom
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              onTap: () => setState(() => _isCustom = true),
            ),
            if (_isCustom) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: "Photo Description",
                  hintText: "e.g., Wearing a summer dress at the beach",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_isCustom && _promptController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please provide a description."),
                      ),
                    );
                    return;
                  }
                  widget.onRequest(_promptController.text.trim(), _isCustom);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Send Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
