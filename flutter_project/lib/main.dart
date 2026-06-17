import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/colors.dart';
import 'core/services/firebase_service.dart';

// Import newly implemented clean feature-first screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/language_selection_screen.dart';
import 'features/login/screens/login_screen.dart';
import 'features/menu/screens/home_menu_browser_screen.dart';
import 'features/menu/screens/product_detail_screen.dart';
import 'features/order/screens/checkout_screen.dart';
import 'features/order/screens/order_tracking_screen.dart';
import 'features/loyalty/screens/profile_loyalty_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lazy init firebase smoothly to guarantee clean startup
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  runApp(
    const ProviderScope(
      child: GrillChickenTikkaApp(),
    ),
  );
}

// Router specification matching feature architectures (feature-first GoRouter routing details)
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/language',
      builder: (BuildContext context, GoRouterState state) {
        return const LanguageSelectionScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeMenuBrowserScreen();
      },
    ),
    GoRoute(
      path: '/product/:id',
      builder: (BuildContext context, GoRouterState state) {
        final productId = state.pathParameters['id'] ?? 'g1';
        return ProductDetailScreen(productId: productId);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (BuildContext context, GoRouterState state) {
        return const CheckoutScreen();
      },
    ),
    GoRoute(
      path: '/order-tracking',
      builder: (BuildContext context, GoRouterState state) {
        return const OrderTrackingScreen();
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileLoyaltyScreen();
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminDashboardScreen();
      },
    ),
  ],
);

class GrillChickenTikkaApp extends StatelessWidget {
  const GrillChickenTikkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Grill Chicken Tikka',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      
      // Multi-language system (Arabic/English support built-in)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'JO'), // Amman Jordan Locale first
      ],
      
      // Artisanal Grill Brand Identity Theme integration
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: ArtisanalColors.primary,
          onPrimary: ArtisanalColors.onPrimary,
          primaryContainer: ArtisanalColors.primaryContainer,
          onPrimaryContainer: ArtisanalColors.onPrimaryContainer,
          secondary: ArtisanalColors.secondary,
          onSecondary: ArtisanalColors.onSecondary,
          secondaryContainer: ArtisanalColors.secondaryContainer,
          onSecondaryContainer: ArtisanalColors.onSecondaryContainer,
          tertiary: ArtisanalColors.tertiary,
          onTertiary: ArtisanalColors.onTertiary,
          background: ArtisanalColors.background,
          onBackground: ArtisanalColors.onBackground,
          surface: ArtisanalColors.surface,
          onSurface: ArtisanalColors.onSurface,
          surfaceVariant: ArtisanalColors.onSurfaceVariant,
          onSurfaceVariant: ArtisanalColors.onSurfaceVariant,
          outline: ArtisanalColors.outline,
          outlineVariant: ArtisanalColors.outlineVariant,
          error: ArtisanalColors.error,
          onError: ArtisanalColors.onError,
          errorContainer: ArtisanalColors.errorContainer,
          onErrorContainer: ArtisanalColors.onErrorContainer,
        ),
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme).copyWith(
          bodyLarge: GoogleFonts.ibmPlexSans(fontSize: 18, color: ArtisanalColors.onSurface),
          bodyMedium: GoogleFonts.ibmPlexSans(fontSize: 16, color: ArtisanalColors.onSurface),
          labelSmall: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardTheme(
          color: ArtisanalColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: ArtisanalColors.primary.withOpacity(0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtisanalColors.primary,
            foregroundColor: ArtisanalColors.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
    );
  }
}
