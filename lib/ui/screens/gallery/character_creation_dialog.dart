import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gallery_model.dart';
import '../../../data/models/character_model.dart';
import '../../../data/repositories/character_repository.dart';
import '../chat/character_chat_screen.dart';
import '../chat/components/summoning_animation_screen.dart';
import '../../../data/utils/image_utils.dart';

class CharacterCreationDialog extends StatefulWidget {
  final GeneratedImage image;

  const CharacterCreationDialog({super.key, required this.image});

  @override
  State<CharacterCreationDialog> createState() =>
      _CharacterCreationDialogState();
}

class _CharacterCreationDialogState extends State<CharacterCreationDialog> {
  final _nameController = TextEditingController();
  String _selectedLanguage = 'en';
  String _selectedGender = 'female';
  bool _isCreating = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English 🇬🇧'},
    {'code': 'id', 'name': 'Indonesia 🇮🇩'},
    {'code': 'es', 'name': 'Español 🇪🇸'},
    {'code': 'pt', 'name': 'Português 🇧🇷'},
    {'code': 'fr', 'name': 'Français 🇫🇷'},
    {'code': 'de', 'name': 'Deutsch 🇩🇪'},
    {'code': 'zh', 'name': '中文 🇨🇳'},
    {'code': 'ja', 'name': '日本語 🇯🇵'},
    {'code': 'ko', 'name': '한국어 🇰🇷'},
    {'code': 'hi', 'name': 'हिन्दी 🇮🇳'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Summon Character",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImageUtils.getFullUrl(widget.image.imageUrl).isNotEmpty
                    ? Image.network(
                        ImageUtils.getFullUrl(widget.image.imageUrl),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                "Character Name",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter name or leave empty for AI",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Language",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguage == lang['code'];
                  return ChoiceChip(
                    label: Text(lang['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedLanguage = lang['code']!);
                      }
                    },
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : Colors.white70,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Gender",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderOption("female", "Female 👩"),
                  const SizedBox(width: 16),
                  _buildGenderOption("male", "Male 👨"),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _handleSummon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Summon Soul",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSummon() async {
    setState(() => _isCreating = true);
    final repository = Provider.of<CharacterRepository>(context, listen: false);

    try {
      final response = await repository.createCharacter(
        imageId: widget.image.id,
        imageUrl: widget.image.imageUrl,
        prompt: widget.image.prompt ?? "",
        language: _selectedLanguage,
        gender: _selectedGender,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        seed: widget.image.seed,
        workflow: widget.image.workflow,
      );

      if (mounted) {
        final characterData = response['character'];
        final characterId = characterData != null
            ? characterData['id']
            : (response['characterId'] ?? response['id'] ?? "");
        final charImageUrl = ImageUtils.getFullUrl(
          response['imageUrl'] ?? widget.image.imageUrl,
        );
        final sinCount = response['sinCount'] ?? 1;
        final rarity = response['rarity'] ?? "Common";

        CharacterModel? initialCharacter;
        final Map<String, dynamic>? charMap = (characterData is Map)
            ? Map<String, dynamic>.from(characterData)
            : null;

        if (charMap != null) {
          try {
            // Helper to ensure relationship data exists (API might omit it for new characters)
            if (charMap['relationship'] == null) {
              charMap['relationship'] = {
                'stage': 'stranger',
                'stageProgress': 0,
                'affectionPoints': 0.0,
                'nextStageThreshold': 500,
                'totalMessages': 0,
                'upgradeAvailable': false,
              };
            }
            initialCharacter = CharacterModel.fromJson(charMap);
          } catch (e) {
            debugPrint("Failed to parse initial character: $e");
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SummoningAnimationScreen(
              characterId: characterId,
              characterImageUrl: ImageUtils.getFullUrl(charImageUrl),
              sinCount: sinCount,
              rarity: rarity,
              onAnimationComplete: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterChatScreen(
                      characterId: characterId,
                      initialCharacter: initialCharacter,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
