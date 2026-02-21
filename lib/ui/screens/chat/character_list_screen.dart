import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/character_model.dart';
import '../../../data/repositories/character_repository.dart';
import 'character_chat_screen.dart';
import '../../components/gem_indicator.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/utils/image_utils.dart';

class CharacterListScreen extends StatelessWidget {
  const CharacterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = Provider.of<CharacterRepository>(context);

    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text("Characters"),
        actions: [
          StreamBuilder<int>(
            stream: drawAiRepo.getGemCountStream(
              authRepo.currentUser?.uid ?? "",
            ),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GemIndicator(
                  gemCount: snapshot.data ?? 0,
                  onClick: () {},
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<List<CharacterModel>>(
        stream: repository.getCharactersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final characters = snapshot.data ?? [];
          if (characters.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: characters.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final character = characters[index];
              return _CharacterListItem(character: character);
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<CharacterModel>>(
        stream: repository.getCharactersStream(),
        builder: (context, snapshot) {
          final characters = snapshot.data ?? [];
          // In a real app, this limit would come from a subscription or config
          // For now, mirroring Android logic or just using a default
          const maxChatLimit = 10;

          if (characters.length >= maxChatLimit) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: () => _navigateToGallery(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _navigateToGallery(BuildContext context) {
    // Navigate to Gallery with selection mode enabled
    Navigator.pushNamed(
      context,
      '/gallery',
      arguments: {'isSelectionMode': true},
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("💬", style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text(
            "No characters yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Summon your first character to start chatting!"),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _navigateToGallery(context),
            child: const Text("Summon Character"),
          ),
        ],
      ),
    );
  }
}

class _CharacterListItem extends StatelessWidget {
  final CharacterModel character;
  const _CharacterListItem({required this.character});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage:
                ImageUtils.getFullUrl(
                  character.imageStorageUrl ?? character.imageUrl,
                ).isNotEmpty
                ? NetworkImage(
                    ImageUtils.getFullUrl(
                      character.imageStorageUrl ?? character.imageUrl,
                    ),
                  )
                : null,
            child:
                ImageUtils.getFullUrl(
                  character.imageStorageUrl ?? character.imageUrl,
                ).isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            character.personality.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatTime(character.relationship.lastInteraction),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(
                  character.relationship.stage.color,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                character.relationship.stage.emoji,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              character.relationship.stage.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CharacterChatScreen(characterId: character.id),
          ),
        );
      },
      onLongPress: () {
        _showDeleteDialog(context);
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return "Now";
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Character?"),
        content: const Text("This will permanently remove your chat history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final repo = Provider.of<CharacterRepository>(
                context,
                listen: false,
              );
              await repo.deleteCharacter(character.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
