import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/character_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/community_repository.dart';
import 'data/repositories/drawai_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/generation_repository.dart';
import 'data/repositories/news_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/gallery_repository.dart';
import 'data/repositories/usage_statistics_repository.dart';
import 'data/repositories/workflow_stats_repository.dart';
import 'data/repositories/app_settings_repository.dart';
import 'services/billing_manager.dart';
import 'data/services/api_service.dart';
import 'data/services/network_module.dart';
import 'data/services/user_preferences.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/community_provider.dart';
import 'data/providers/generate_provider.dart';
import 'data/providers/inventory_provider.dart';
import 'data/providers/main_provider.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'data/providers/settings_provider.dart';
import 'data/providers/navigation_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/auth/onboarding_screen.dart';
import 'firebase_options.dart';

import 'services/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const AnimeDrawApp(),
    ),
  );
}

class AnimeDrawApp extends StatefulWidget {
  const AnimeDrawApp({super.key});

  @override
  State<AnimeDrawApp> createState() => _AnimeDrawAppState();
}

class _AnimeDrawAppState extends State<AnimeDrawApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Preload App Open ad on app start
    AdManager.loadAppOpenAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (FirebaseAuth.instance.currentUser != null) {
        AdManager.showAppOpenAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => NetworkModule.getApiService()),
        Provider(create: (_) => UserPreferences()),

        // Repositories
        Provider(create: (_) => AuthRepository()),
        ProxyProvider<ApiService, CharacterRepository>(
          update: (_, api, __) => CharacterRepository(api),
        ),
        ProxyProvider<ApiService, ChatRepository>(
          update: (_, api, __) => ChatRepository(api),
        ),
        Provider(create: (_) => CommunityRepository()),
        Provider(create: (_) => FavoritesRepository()),
        Provider(create: (_) => GenerationRepository()),
        Provider(create: (_) => NewsRepository()),
        Provider(create: (_) => WorkflowStatsRepository()),
        Provider(create: (_) => AppSettingsRepository()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // Repositories that depend on userId (dynamic)
        ProxyProvider<AuthRepository, UsageStatisticsRepository?>(
          update: (_, auth, __) {
            final user = auth.currentUser;
            if (user == null) return null;
            return UsageStatisticsRepository(userId: user.uid);
          },
        ),
        ProxyProvider<UsageStatisticsRepository?, GalleryRepository>(
          update: (_, stats, __) => GalleryRepository(stats),
        ),
        ProxyProvider<AuthRepository, SubscriptionRepository?>(
          update: (_, auth, __) {
            final user = auth.currentUser;
            if (user == null) return null;
            return SubscriptionRepository(user.uid);
          },
        ),

        // Repositories that depend on others
        ProxyProvider5<
          ApiService,
          GenerationRepository,
          GalleryRepository,
          UsageStatisticsRepository?,
          WorkflowStatsRepository,
          DrawAiRepository
        >(
          update: (_, api, gen, gallery, stats, wfStats, __) =>
              DrawAiRepository(api, gen, gallery, stats, wfStats),
        ),

        // State Management Providers (ViewModel equivalents)
        ChangeNotifierProxyProvider2<
          AuthRepository,
          GenerationRepository,
          MainProvider
        >(
          create: (ctx) => MainProvider(
            ctx.read<AuthRepository>(),
            ctx.read<GenerationRepository>(),
          ),
          update: (_, auth, gen, prev) => prev ?? MainProvider(auth, gen),
        ),
        ChangeNotifierProxyProvider<CommunityRepository, CommunityProvider>(
          create: (ctx) => CommunityProvider(ctx.read<CommunityRepository>()),
          update: (_, repo, prev) => prev ?? CommunityProvider(repo),
        ),
        ChangeNotifierProxyProvider3<
          DrawAiRepository,
          AuthRepository,
          WorkflowStatsRepository,
          GenerateProvider
        >(
          create: (ctx) => GenerateProvider(
            ctx.read<DrawAiRepository>(),
            ctx.read<AuthRepository>(),
            ctx.read<WorkflowStatsRepository>(),
          ),
          update: (_, draw, auth, wf, prev) =>
              prev ?? GenerateProvider(draw, auth, wf),
        ),
        ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
          create: (ctx) => ChatProvider(ctx.read<ChatRepository>()),
          update: (_, repo, prev) => prev ?? ChatProvider(repo),
        ),
        ChangeNotifierProxyProvider<DrawAiRepository, InventoryProvider>(
          create: (ctx) => InventoryProvider(ctx.read<DrawAiRepository>()),
          update: (_, repo, prev) => prev ?? InventoryProvider(repo),
        ),
        ChangeNotifierProxyProvider<SubscriptionRepository?, BillingManager>(
          create: (_) => BillingManager(
            SubscriptionRepository(""),
          ), // Initialize empty, update handles real Auth payload
          update: (_, repo, prev) {
            if (repo == null) {
              return prev ?? BillingManager(SubscriptionRepository(""));
            }
            return prev ?? BillingManager(repo);
          },
        ),
      ],
      child: MaterialApp(
        title: 'AnimeDraw AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(settings.themeColor),
        darkTheme: AppTheme.darkTheme(settings.themeColor),
        themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository>(context);
    final settings = Provider.of<SettingsProvider>(context);

    if (settings.isFirstLaunch) {
      return OnboardingScreen(onFinish: settings.setFirstLaunchComplete);
    }

    return StreamBuilder(
      stream: authRepo.authStateChanges,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        // If we have data (even from initialData), show main screen
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Only show loading if we are explicitly waiting and have no data
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
