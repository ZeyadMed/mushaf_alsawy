import 'package:go_router/go_router.dart';
import 'package:mushaf_alsawy/core/router/bottom_nav_app.dart';
import 'package:mushaf_alsawy/features/splash/presentation/view/splash_screen.dart';
import 'package:mushaf_alsawy/main.dart';

abstract class AppRouter {
  static const String root = '/';
  static const String onboarding = '/onboarding';

  // ************* HOME *************
  static const String initialRoot = '/initialRoot';
  static const String homeScreen = '/HomeScreen';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      // -----------------------------------Splash Screen and OnBoarding--------------------------------
      GoRoute(
        path: root,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: initialRoot,
        builder: (context, state) => const BottomNavApp(),
      ),

      // GoRoute(
      //   path: homeScreen,
      //   builder: (context, state) => const HomeScreen(),
      // ),
    ],
  );
}
