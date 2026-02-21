import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/utils/image_utils.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/repositories/character_repository.dart';
import 'dart:math' as math;
import 'components/relationship_dialog.dart';
import 'components/inventory_dialog.dart';
import 'components/photo_request_dialog.dart';

class CharacterChatScreen extends StatefulWidget {
  final String characterId;
  final CharacterModel? initialCharacter;

  const CharacterChatScreen({
    super.key,
    required this.characterId,
    this.initialCharacter,
  });

  @override
  State<CharacterChatScreen> createState() => _CharacterChatScreenState();
}

class _CharacterChatScreenState extends State<CharacterChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CharacterMessage> _messages = [];
  bool _isSending = false;
  CharacterModel? _character;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    final history = await repo.getChatHistory(widget.characterId);
    if (mounted) {
      setState(() {
        _messages = history;
      });
      _scrollToBottom(animated: false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    void scroll() {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxExtent);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => scroll());

    // Attempt to safely scroll several times to capture rendering updates (e.g. late images or keyboard popping)
    Future.delayed(const Duration(milliseconds: 50), scroll);
    Future.delayed(const Duration(milliseconds: 150), scroll);
    Future.delayed(const Duration(milliseconds: 300), scroll);
    Future.delayed(const Duration(milliseconds: 600), scroll);
  }

  bool _containsRudeWords(String text) {
    final rudeWords = [
      'fuck',
      'shit',
      'bitch',
      'asshole',
      'dick',
      'pussy',
      'porn',
      'sex',
    ];
    final lowerText = text.toLowerCase();
    return rudeWords.any((word) => lowerText.contains(word));
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_containsRudeWords(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please keep the conversation respectful."),
        ),
      );
      return;
    }

    final repo = Provider.of<CharacterRepository>(context, listen: false);

    setState(() {
      _isSending = true;
      // Optimistic update
      _messages.add(
        CharacterMessage(
          id: DateTime.now().toString(),
          characterId: widget.characterId,
          role: 'user',
          content: text,
          timestamp: DateTime.now(),
          relationshipStage:
              _character?.relationship.stage ?? RelationshipStage.stranger,
        ),
      );
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final stopwatch = Stopwatch()..start();
      final response = await repo.sendMessage(widget.characterId, text);
      stopwatch.stop();

      // Add a random delay to simulate realistic typing (0.5s - 3s)
      final random = math.Random();
      final targetDelayMs = 500 + random.nextInt(2501);
      final remainingMs = targetDelayMs - stopwatch.elapsedMilliseconds;
      if (remainingMs > 0) {
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      if (response['success'] == true) {
        final replyJson = response['message'] ?? response['response_message'];
        if (replyJson != null) {
          final reply = CharacterMessage.fromJson(replyJson);
          setState(() {
            _messages.add(reply);
          });
          _scrollToBottom();
        } else if (response['response'] != null) {
          // Fallback if full message object is not returned
          setState(() {
            _messages.add(
              CharacterMessage(
                id: response['id'] ?? DateTime.now().toString(),
                characterId: widget.characterId,
                role: 'assistant',
                content: response['response'],
                timestamp: DateTime.now(),
                relationshipStage:
                    _character?.relationship.stage ??
                    RelationshipStage.stranger,
              ),
            );
          });
          _scrollToBottom();
        } else {
          // Final fallback: Reload history if no direct response found
          await _loadChatHistory();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showRelationshipDialog() {
    if (_character == null) return;
    showDialog(
      context: context,
      builder: (context) => RelationshipDialog(character: _character!),
    );
  }

  void _showCombinedMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text("Give a Gift"),
              onTap: () {
                Navigator.pop(context);
                _showGiftingDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Request a Photo"),
              onTap: () {
                Navigator.pop(context);
                _showPhotoRequestDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftingDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          InventoryDialog(onSelectItem: (item) => _handleSendGift(item)),
    );
  }

  Future<void> _handleSendGift(InventoryItemModel item) async {
    Navigator.pop(context); // Close dialog
    final repo = Provider.of<CharacterRepository>(context, listen: false);

    try {
      final response = await repo.sendGift(widget.characterId, item.id);
      if (response['success'] == true) {
        final affectionAdded =
            response['affectionAdded'] ?? item.affectionValue;
        _showAffectionBubble(affectionAdded);
        await _loadChatHistory();
      } else {
        throw Exception(response['error'] ?? "Failed to send gift");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showAffectionBubble(num points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.pink, size: 20),
            const SizedBox(width: 8),
            Text("+$points Affection with ${_character?.personality.name}"),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        width: 250,
      ),
    );
  }

  void _showPhotoRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => PhotoRequestDialog(
        onRequest: (prompt, isCustom) => _handlePhotoRequest(prompt, isCustom),
      ),
    );
  }

  String _getChatContext() {
    final recentMessages = _messages.length > 6
        ? _messages.sublist(_messages.length - 6)
        : _messages;
    return recentMessages
        .map((msg) {
          final role = msg.role == 'user' ? 'User' : 'Character';
          return "$role: ${msg.content}";
        })
        .join("\n");
  }

  Future<void> _handlePhotoRequest(String prompt, bool isCustom) async {
    final repo = Provider.of<CharacterRepository>(context, listen: false);
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    try {
      final response = await repo.requestPhoto(
        characterId: widget.characterId,
        userPrompt: isCustom ? prompt : "",
        appearancePrompt: _character?.personality.appearance ?? "",
        chatContext: _getChatContext(),
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo request sent! She's working on it..."),
            ),
          );
        }

        // Handle generation orchestration (Sync with Android logic)
        if (response['action'] == 'generate_image' &&
            response['generationParams'] != null) {
          final params = response['generationParams'] as Map<String, dynamic>;

          // Start generation
          final genResult = await drawAiRepo.generateAndWait(
            positivePrompt: params['prompt'] ?? "",
            negativePrompt: params['negative_prompt'] ?? "",
            workflow: params['workflow_id'] ?? "standard",
            userId: userId,
            seed: params['seed'],
            width: params['width'],
            height: params['height'],
            onStatusUpdate: (statusText, statusResponse) {
              if (mounted && statusText.isNotEmpty) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(statusText),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          );

          if (genResult.status == "completed" &&
              genResult.downloadUrls != null) {
            final imageUrl = genResult.downloadUrls!.first;
            final caption = params['caption'] ?? "Ini fotoku! 📸";

            // Inject message to chat history
            await repo.injectMessage(
              characterId: widget.characterId,
              role: "assistant",
              content: caption,
              imageUrl: imageUrl,
            );

            // Fetch history to show the new message
            _loadChatHistory();
          }
        }
      } else {
        throw Exception(response['error'] ?? "Failed to request photo");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CharacterRepository>(context);
    final theme = Theme.of(context);

    return StreamBuilder<CharacterModel?>(
      stream: repo.getCharacterStream(widget.characterId),
      initialData: widget.initialCharacter,
      builder: (context, snapshot) {
        _character = snapshot.data;
        final character = _character;

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: _showRelationshipDialog,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: () {
                      final sUrl = character?.imageStorageUrl;
                      if (sUrl != null && sUrl.isNotEmpty) {
                        return NetworkImage(sUrl);
                      }
                      final cUrl = character?.imageUrl;
                      final resolvedUrl = ImageUtils.getFullUrl(cUrl);
                      if (resolvedUrl.isNotEmpty) {
                        return NetworkImage(resolvedUrl);
                      }
                      return null;
                    }(),
                    child: () {
                      final sUrl = character?.imageStorageUrl;
                      final cUrl = character?.imageUrl;
                      final resolvedUrl = ImageUtils.getFullUrl(cUrl);
                      if ((sUrl == null || sUrl.isEmpty) &&
                          resolvedUrl.isEmpty) {
                        return const Icon(Icons.person, size: 24);
                      }
                      return null;
                    }(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character?.personality.name ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          character?.relationship.stage.displayName ?? "",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message.role == 'user';

                    return _MessageBubble(message: message, isUser: isUser);
                  },
                ),
              ),
              if (_isSending && _character != null)
                _TypingIndicator(character: _character!),
              _buildInputArea(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showCombinedMenu,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CharacterMessage message;
  final bool isUser;

  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: message.imageUrl != null
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        clipBehavior: message.imageUrl != null ? Clip.antiAlias : Clip.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null &&
                ImageUtils.getFullUrl(message.imageUrl).isNotEmpty)
              CachedNetworkImage(
                imageUrl: ImageUtils.getFullUrl(message.imageUrl!),
                placeholder: (context, url) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
              ),
            if (message.content.isNotEmpty)
              Padding(
                padding: message.imageUrl != null
                    ? const EdgeInsets.all(12.0)
                    : EdgeInsets.zero,
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final CharacterModel character;

  const _TypingIndicator({required this.character});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = widget.character;

    // Resolve Avatar URL
    final sUrl = character.imageStorageUrl;
    final cUrl = character.imageUrl;
    final resolvedUrl = ImageUtils.getFullUrl(cUrl);
    ImageProvider? avatarProvider;
    if (sUrl != null && sUrl.isNotEmpty) {
      avatarProvider = NetworkImage(sUrl);
    } else if (resolvedUrl.isNotEmpty) {
      avatarProvider = NetworkImage(resolvedUrl);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final t =
                            (_controller.value * 2 * math.pi) - (index * 1.5);
                        final alpha = (math.sin(t) + 1) / 2 * 0.7 + 0.3;

                        return Opacity(
                          opacity: alpha.clamp(0.0, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  character.relationship.stage.emoji,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
