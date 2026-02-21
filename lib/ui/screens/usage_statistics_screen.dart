import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Displays user usage statistics: total generations, favorites, gems.
/// Equivalent to Android's UsageStatisticsScreen.
class UsageStatisticsScreen extends StatefulWidget {
  const UsageStatisticsScreen({super.key});

  @override
  State<UsageStatisticsScreen> createState() => _UsageStatisticsScreenState();
}

class _UsageStatisticsScreenState extends State<UsageStatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('generation_limits')
            .doc(uid)
            .get(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        FirebaseFirestore.instance.collection('user_favorites').doc(uid).get(),
      ]);

      final limitDoc = results[0];
      final userDoc = results[1];
      final favDoc = results[2];

      final totalGenerations =
          (limitDoc.data()?['totalGenerations'] as int?) ?? 0;
      final gems = (userDoc.data()?['gems'] as int?) ?? 0;
      final favoriteIds = favDoc.data()?['workflowIds'] as List? ?? [];

      setState(() {
        _stats = {
          'totalGenerations': totalGenerations,
          'gems': gems,
          'favorites': favoriteIds.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        title: const Text('Usage Statistics'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStats,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Activity',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StatCard(
                      icon: Icons.auto_awesome,
                      iconColor: Colors.purpleAccent,
                      label: 'Total Generations',
                      value: '${_stats?['totalGenerations'] ?? 0}',
                      subtitle: 'Images created',
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.favorite,
                      iconColor: Colors.pinkAccent,
                      label: 'Favorites',
                      value: '${_stats?['favorites'] ?? 0}',
                      subtitle: 'Saved workflows',
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.diamond,
                      iconColor: Colors.cyanAccent,
                      label: 'Gems',
                      value: '${_stats?['gems'] ?? 0}',
                      subtitle: 'Current balance',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
