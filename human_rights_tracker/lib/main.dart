import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Firebase options
import 'core/routes.dart';
import 'features/ui/landing_page.dart';
import 'features/ui/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RightsTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // If user is logged in
          if (snapshot.hasData) {
            return const HomePage();
          }
          // If user is NOT logged in
          return const LandingPage();
        },
      ),
      onGenerateRoute: (settings) {
        // If user is not logged in, always show landing/login/signup
        if (settings.name == AppRoutes.landing || 
            settings.name == AppRoutes.login || 
            settings.name == AppRoutes.signup) {
          return AppRoutes.generateRoute(settings);
        }
        // For all other routes, check auth
        if (FirebaseAuth.instance.currentUser == null) {
          // Not logged in, redirect to login
          return AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.login));
        }
        // Logged in, allow navigation
        return AppRoutes.generateRoute(settings);
      },
    );
  }
}

