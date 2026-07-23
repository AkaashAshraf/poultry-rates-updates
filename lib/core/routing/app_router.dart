import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/admin_login_screen.dart';
import '../../screens/auth/admin_otp_screen.dart';
import '../../screens/user/shell/user_shell_screen.dart';
import '../../screens/admin/shell/admin_shell_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
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
