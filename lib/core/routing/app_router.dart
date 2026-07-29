import 'package:go_router/go_router.dart';
import '../../models/app_version_config_model.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/splash/force_update_screen.dart';
import '../../screens/onboarding/language_selection_screen.dart';
import '../../screens/onboarding/welcome_screen.dart';
import '../../screens/onboarding/city_onboarding_screen.dart';
import '../../screens/auth/admin_login_screen.dart';
import '../../screens/auth/admin_otp_screen.dart';
import '../../screens/user/shell/user_shell_screen.dart';
import '../../screens/admin/shell/admin_shell_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String forceUpdate = '/force-update';
  static const String languageSelect = '/language-select';
  static const String welcome = '/welcome';
  static const String cityOnboarding = '/city-onboarding';
  static const String userHome = '/home';
  static const String adminLogin = '/admin-login';
  static const String adminOtp = '/admin-otp';
  static const String adminHome = '/admin';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.forceUpdate,
      // The version config is handed over from SplashScreen via `extra`
      // rather than re-fetched here, so there's exactly one Firestore read
      // per cold start.
      builder: (context, state) => ForceUpdateScreen(config: state.extra as AppVersionConfig),
    ),
    GoRoute(
      path: AppRoutes.languageSelect,
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.cityOnboarding,
      builder: (context, state) => const CityOnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.userHome,
      builder: (context, state) => const UserShellScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminLogin,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminOtp,
      builder: (context, state) => const AdminOtpScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminHome,
      builder: (context, state) => const AdminShellScreen(),
    ),
  ],
);
