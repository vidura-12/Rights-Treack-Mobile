import 'package:flutter/material.dart';
import '../features/ui/landing_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/SignUpPage.dart';
import '../features/ui/HomePage.dart'; // Remove this import if it's causing conflicts
import '../features/ui/media.dart' as media_file; // Use prefix for media
import '../features/ui/text.dart' as support_file; // Use prefix for support
import '../features/ui/report_case_page.dart';
import '../features/ui/case_list_page.dart';
import '../features/ui/case_charts_page.dart';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String media = '/media';
  static const String support = '/support';

  static const String reportCase = '/report-case';
  static const String displayCase = '/display-case';
  static const String displayChart = '/display-chart';

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
      case media:
        return MaterialPageRoute(builder: (_) => media_file.MediaPage(isDarkTheme: true));
      case support:
        return MaterialPageRoute(builder: (_) => support_file.UserSupportPage(isDarkTheme: true));
      case reportCase:
        return MaterialPageRoute(builder: (_) => const ReportCasePage(isDarkTheme: true));
      case displayCase:
        return MaterialPageRoute(builder: (_) => const CaseListPage());
      case displayChart:
        return MaterialPageRoute(builder: (_) => const CaseChartsPage());
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