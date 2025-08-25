import 'package:flutter/material.dart';
import '../../core/routes.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animations
    _controller.forward();

    // Auto-navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051338),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1F4D),
              Color(0xFF051338),
              Color(0xFF030A23),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main content centered
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: const Text(
                          'RightsTrack',
                          style: TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black54,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Animated Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: const Text(
                          'Justice Starts With Awareness',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Ink drop animation at the bottom
            Positioned(
              bottom: 50,
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
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
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