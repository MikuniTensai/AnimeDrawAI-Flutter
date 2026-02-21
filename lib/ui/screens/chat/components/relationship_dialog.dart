import 'package:flutter/material.dart';
import '../../../../data/models/character_model.dart';
import '../../../../data/utils/image_utils.dart';

class RelationshipDialog extends StatelessWidget {
  final CharacterModel character;

  const RelationshipDialog({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(character: character),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: "Relationship"),
                Tab(text: "Status"),
                Tab(text: "Profile"),
                Tab(text: "Stats"),
              ],
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  _RelationshipTab(character: character),
                  _StatusTab(character: character),
                  _ProfileTab(character: character),
                  _StatsTab(character: character),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final CharacterModel character;

  const _DialogHeader({required this.character});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 0,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: CircleAvatar(
              radius: 36,
              backgroundImage:
                  ImageUtils.getFullUrl(character.imageUrl).isNotEmpty
                  ? NetworkImage(ImageUtils.getFullUrl(character.imageUrl))
                  : null,
              child: ImageUtils.getFullUrl(character.imageUrl).isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
        ),
        Positioned(
          left: 104,
          bottom: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.personality.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                character.relationship.stage.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelationshipTab extends StatelessWidget {
  final CharacterModel character;

  const _RelationshipTab({required this.character});

  @override
  Widget build(BuildContext context) {
    final status = character.relationship;

    // Safety handling for max stage
    final isMax = status.stage == RelationshipStage.married;
    final progress = isMax
        ? 1.0
        : (status.nextStageThreshold > 0
              ? (status.affectionPoints / status.nextStageThreshold).clamp(
                  0.0,
                  1.0,
                )
              : 0.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big Stage Display
        Column(
          children: [
            Text(status.stage.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              status.stage.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(status.stage.color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Progress Card
        _ProgressCard(status: status, isMax: isMax, progress: progress),
        const SizedBox(height: 16),

        // Roadmap
        _RelationshipRoadmap(currentStage: status.stage),

        const SizedBox(height: 16),

        if (status.upgradeAvailable)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                // Handle upgrade logic here
              },
              child: Text(
                status.stage == RelationshipStage.bestFriend
                    ? "💌 Confess Feelings"
                    : "💍 Propose Marriage",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final RelationshipStatus status;
  final bool isMax;
  final double progress;

  const _ProgressCard({
    required this.status,
    required this.isMax,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Affection Points",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (isMax)
                const Text(
                  "MAX ❤️",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  "${status.affectionPoints.toInt()} / ${status.nextStageThreshold}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(status.stage.color),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isMax) ...[
            Builder(
              builder: (context) {
                final stages = RelationshipStage.values;
                final currentIndex = stages.indexOf(status.stage);
                final nextStage = currentIndex + 1 < stages.length
                    ? stages[currentIndex + 1]
                    : stages.last;
                final pointsNeeded =
                    (status.nextStageThreshold - status.affectionPoints)
                        .toInt()
                        .clamp(0, 99999);

                return Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$pointsNeeded AP to ${nextStage.displayName}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox(
              width: double.infinity,
              child: Text(
                "Soulmate Forever 💍",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelationshipRoadmap extends StatelessWidget {
  final RelationshipStage currentStage;

  const _RelationshipRoadmap({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Relationship Roadmap",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RelationshipStage.values.map((stage) {
                final isAchieved = stage.index <= currentStage.index;
                final isCurrent = stage == currentStage;

                return Row(
                  children: [
                    Opacity(
                      opacity: isAchieved ? 1.0 : 0.4,
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Color(stage.color).withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(
                                      color: Color(stage.color),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Text(
                              stage.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? Color(stage.color)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stage != RelationshipStage.values.last)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final CharacterModel character;

  const _StatusTab({required this.character});

  @override
  Widget build(BuildContext context) {
    final emotionalState = character.emotionalState;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(
          title: "Current Mood",
          icon: "😊",
          child: Text(
            emotionalState.currentMood.replaceFirst(
              emotionalState.currentMood[0],
              emotionalState.currentMood[0].toUpperCase(),
            ),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StatusCard(
          title: "Energy Level",
          icon: "⚡",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${emotionalState.energyLevel}%",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    emotionalState.energyLevel > 70
                        ? "High"
                        : emotionalState.energyLevel > 30
                        ? "Normal"
                        : "Tired",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (emotionalState.energyLevel / 100.0).clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    emotionalState.energyLevel > 70
                        ? Colors.green
                        : emotionalState.energyLevel > 30
                        ? Colors.amber
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final CharacterModel character;

  const _ProfileTab({required this.character});

  @override
  Widget build(BuildContext context) {
    final personality = character.personality;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(
          title: "Morning Alarm",
          icon: "⏰",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Greeting",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      character.notificationUnlocked
                          ? "Receive daily messages from ${personality.name}"
                          : "Unlock daily messages from ${personality.name} (250 Gems)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: character.notificationEnabled, onChanged: (val) {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatusCard(
          title: "Archetype",
          icon: "🎭",
          child: Text(
            personality.archetype,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        if (personality.traits.isNotEmpty)
          _StatusCard(
            title: "Traits",
            icon: "✨",
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: personality.traits.map((trait) {
                return Chip(
                  label: Text(trait, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        if (personality.traits.isNotEmpty) const SizedBox(height: 16),
        if (personality.interests.isNotEmpty)
          _StatusCard(
            title: "Interests",
            icon: "💖",
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: personality.interests.map((interest) {
                return Chip(
                  label: Text(interest, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        if (personality.interests.isNotEmpty) const SizedBox(height: 16),
        _StatusCard(
          title: "Deadly Sins",
          icon: "😈",
          child: Text(
            "${personality.sinCount} Sins (Hidden)",
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final CharacterModel character;

  const _StatsTab({required this.character});

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return "Never";
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final relationship = character.relationship;
    final patterns = character.interactionPatterns;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(
          title: "Interaction Stats",
          icon: "📊",
          child: Column(
            children: [
              _StatRow(
                label: "Total Messages",
                value: "${relationship.totalMessages}",
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: "Last Chat",
                value: _formatRelativeTime(relationship.lastChatDate),
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: "Chat Frequency",
                value: patterns.chatFrequency.isNotEmpty
                    ? patterns.chatFrequency.replaceFirst(
                        patterns.chatFrequency[0],
                        patterns.chatFrequency[0].toUpperCase(),
                      )
                    : "Unknown",
              ),
            ],
          ),
        ),
        if (patterns.totalGhostsDetected > 0) ...[
          const SizedBox(height: 16),
          _StatusCard(
            title: "Ghosting Record",
            icon: "👻",
            containerColor: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Text(
              "You have ghosted this character ${patterns.totalGhostsDetected} times.",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;
  final Color? containerColor;

  const _StatusCard({
    required this.title,
    required this.icon,
    required this.child,
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color:
          containerColor ??
          Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
