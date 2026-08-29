import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/competitive_provider.dart';
import 'providers/match_provider.dart';
import 'providers/store_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/riot_auth_service.dart';
import 'services/riot_collection_service.dart';
import 'services/riot_competitive_service.dart';
import 'services/riot_match_service.dart';
import 'services/riot_store_service.dart';
import 'services/secure_storage_service.dart';
import 'services/store_history_service.dart';
import 'services/valorant_assets_service.dart';

class ValoMagazaApp extends StatelessWidget {
  const ValoMagazaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SecureStorageService()),
        Provider(create: (_) => NotificationService()..initialize()),
        Provider(create: (_) => StoreHistoryService()),
        Provider(
          create: (context) =>
              RiotAuthService(context.read<SecureStorageService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(context.read<RiotAuthService>())..initialize(),
        ),
        Provider(create: (_) => RiotStoreService()),
        Provider(create: (_) => RiotMatchService()),
        Provider(create: (_) => RiotCollectionService()),
        Provider(create: (_) => RiotCompetitiveService()),
        Provider(create: (_) => ValorantAssetsService()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
          create: (context) => StoreProvider(
            context.read<RiotStoreService>(),
            context.read<ValorantAssetsService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, auth, provider) => provider!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, MatchProvider>(
          create: (context) => MatchProvider(
            context.read<RiotMatchService>(),
            context.read<ValorantAssetsService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, auth, provider) => provider!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, CollectionProvider>(
          create: (context) => CollectionProvider(
            context.read<RiotCollectionService>(),
            context.read<ValorantAssetsService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, auth, provider) => provider!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, CompetitiveProvider>(
          create: (context) => CompetitiveProvider(
            context.read<RiotCompetitiveService>(),
            context.read<ValorantAssetsService>(),
            context.read<AuthProvider>(),
          ),
          update: (_, auth, provider) => provider!,
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledUri;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  void _onUriReceived(Uri uri) {
    final uriString = uri.toString();
    if (_lastHandledUri == uriString) return;
    _lastHandledUri = uriString;
    if (mounted) {
      context.read<AuthProvider>().handleIncomingLink(uri);
    }
  }

  Future<void> _initDeepLinks() async {
    // Uygulama tamamen kapalıyken gelen link (cold start)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _onUriReceived(initialLink);
    }

    // Uygulama arka planda ya da ön plandayken gelen link (warm/hot start)
    _linkSubscription = _appLinks.uriLinkStream.listen(_onUriReceived);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, child) {
        switch (auth.status) {
          case AuthStatus.initializing:
            return const SplashScreen();
          case AuthStatus.signedIn:
            return const HomeShell();
          case AuthStatus.signedOut:
          case AuthStatus.authenticating:
            return const LoginScreen();
        }
      },
    );
  }
}
