import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppWrapper extends StatelessWidget {
  final Widget child;
  final Brightness statusBarIconBrightness;
  final Color navigationBarColor;

  const AppWrapper({
    super.key,
    required this.child,
    this.statusBarIconBrightness = Brightness.light,
    this.navigationBarColor = const Color(0xFF030A23),
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: statusBarIconBrightness,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF051338),
        body: SafeArea(
          bottom: false,
          child: child,
        ),
      ),
    );
  }
}