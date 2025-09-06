import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes.dart';
import '../../core/app_wrapper.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar style
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0A1628),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animations
    _controller.forward();

    // Auto-navigate after 4.0 seconds
    Future.delayed(const Duration(milliseconds: 4000), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Reset status bar settings when leaving this page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0A1628),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Static text content centered
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RightsTrack',
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Color(0xFF0A1628),
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                  ],
                ),
              ),
            ),
            
            // Ink drop animation at the bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 50,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: InkDropPainter(_rippleAnimation.value),
                      size: const Size(100, 100),
                    );
                  },
                ),
              ),
            ),
            
            // Loading text at the bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InkDropPainter extends CustomPainter {
  final double animationValue;

  InkDropPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // Main drop
    final mainPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Ripple circles
    final ripplePaint = Paint()
      ..color = Colors.white.withOpacity(0.3 - (animationValue * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw main drop
    canvas.drawCircle(center, maxRadius * 0.4, mainPaint);
    
    // Draw ripples
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (animationValue - (i * 0.2)).clamp(0.0, 1.0);
      if (rippleProgress > 0) {
        final radius = maxRadius * 0.4 + (maxRadius * 0.6 * rippleProgress);
        canvas.drawCircle(center, radius, ripplePaint);
      }
    }
    
    // Draw splash effect
    final splashPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * (1 - animationValue))
      ..style = PaintingStyle.fill;
    
    final splashRadius = maxRadius * (0.5 + animationValue * 0.5);
    canvas.drawCircle(center, splashRadius, splashPaint);
  }

  @override
  bool shouldRepaint(covariant InkDropPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}