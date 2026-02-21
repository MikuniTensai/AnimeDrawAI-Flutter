import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/generation_repository.dart';
import '../../data/providers/navigation_provider.dart';
import 'home/home_screen.dart';
import 'chat/character_list_screen.dart';
import 'community/community_screen.dart';
import 'gallery/gallery_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/settings_screen.dart';
import 'inventory_screen.dart';
import 'leaderboard_screen.dart';
import 'subscription_screen.dart';
import 'content/vision_screen.dart'; // Added
import 'chat/chat_screen.dart'; // Added
import 'news_screen.dart'; // Added
import 'usage_statistics_screen.dart'; // Added

import '../components/app_drawer.dart';
import '../components/animated_bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _subscriptionExpiryListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final genRepo = Provider.of<GenerationRepository>(context, listen: false);
      _subscriptionExpiryListener = genRepo.onSubscriptionExpired.listen((_) {
        _showSubscriptionExpiredDialog();
      });
    });
  }

  @override
  void dispose() {
    _subscriptionExpiryListener?.cancel();
    super.dispose();
  }

  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Subscription Expired"),
        content: const Text(
          "Your subscription has expired. You have been downgraded to the Free plan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  final List<String> _routeNames = [
    "home",
    "community",
    "gallery",
    "chat",
    "profile",
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const CommunityScreen(),
    const GalleryScreen(),
    const CharacterListScreen(),
    const ProfileScreen(),
  ];

  void _onDrawerNavigate(String route) {
    _scaffoldKey.currentState?.closeDrawer();

    final index = _routeNames.indexOf(route);
    if (index != -1) {
      Provider.of<NavigationProvider>(context, listen: false).setIndex(index);
    } else {
      // Handle routes that are not in the bottom nav
      switch (route) {
        case "inventory":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InventoryScreen()),
          );
          break;
        case "leaderboard":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
          );
          break;
        case "settings":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          break;
        case "subscription":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
          break;
        case "vision":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VisionScreen()),
          );
          break;
        case "general_chat":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
          break;
        case "favorites":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GalleryScreen(showFavorites: true),
            ),
          );
          break;
        case "news":
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewsScreen()),
          );
          break;
        case "usage_stats":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UsageStatisticsScreen(),
            ),
          );
          break;
        default:
          debugPrint("Navigating to $route - Not implemented");
      }
    }
  }

  Widget _buildBody(NavigationProvider navProvider) {
    final index = navProvider.currentIndex;
    final arguments = navProvider.arguments;

    if (index == 2) {
      // Gallery
      final isSelectionMode = arguments?['isSelectionMode'] ?? false;
      return GalleryScreen(isSelectionMode: isSelectionMode);
    }

    return _screens[index];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawer(
            currentRoute: _routeNames[navProvider.currentIndex],
            onNavigate: _onDrawerNavigate,
          ),
          body: _buildBody(navProvider),
          bottomNavigationBar: AnimatedBottomNavigation(
            currentIndex: navProvider.currentIndex,
            onTap: (index) => navProvider.setIndex(index),
          ),
        );
      },
    );
  }
}
