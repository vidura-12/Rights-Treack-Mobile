import 'package:flutter/material.dart';
import '../features/ui/landing_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/SignUpPage.dart';
import '../features/ui/HomePage.dart';
import '../features/ui/report_case_page.dart';
class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String reportCase = '/report-case';
  // Add other routes as needed

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case reportCase:
        return MaterialPageRoute(builder: (_) => const ReportCasePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
