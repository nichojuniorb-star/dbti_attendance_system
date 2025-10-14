import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Required for Future.delayed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  // Controls the overall sequence (navigation timing)
  late AnimationController _sequenceController; 
  
  // Controls the "Explosion" visual transition (gradient stop)
  late Animation<double> _gradientAnimation;

  // For the visual "Raindrop/Swinging" effect
  late AnimationController _rainController;
  late Animation<Alignment> _alignAnimation;

  final Duration _rainDuration = const Duration(seconds: 3);
  final Duration _explosionDuration = const Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();

    // 1. RAINDROP PHASE setup (3.0s)
    _rainController = AnimationController(
      vsync: this,
      duration: _rainDuration,
    )..repeat(reverse: true);

    _alignAnimation = AlignmentTween(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(parent: _rainController, curve: Curves.easeInOut));

    // 2. EXPLOSION PHASE setup (1.5s)
    // We use a separate controller/animation for the sharp gradient reveal
    _sequenceController = AnimationController(
      vsync: this,
      duration: _rainDuration + _explosionDuration,
    );

    // This animation starts immediately at 0.0 and quickly jumps to 1.0 after the rain phase
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        // Start curve only after the rain phase duration
        curve: Interval(_rainDuration.inMilliseconds / (3000 + 1500), 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Start the full sequence
    _sequenceController.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for both animation phases to complete (4.5 seconds total)
    await Future.delayed(_rainDuration + _explosionDuration + const Duration(milliseconds: 500)); 

    if (!mounted) return;
    
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      Navigator.pushReplacementNamed(context, '/home'); 
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder listens to the sequence controller to drive both effects
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_rainController, _sequenceController]),
        builder: (context, child) {
          // Determine the alignment for the swinging gradient (Raindrop effect)
          Alignment currentAlignment = _alignAnimation.value;

          // Determine the stop point for the gradient reveal (Explosion effect)
          double currentStop = _gradientAnimation.value;

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient( // Use RadialGradient for the explosion effect
                center: currentAlignment, // Swinging alignment for dynamic color base
                radius: currentStop * 2.5, // Animate radius from small (0) to large (>1)
                colors: const [
                  Color(0xFF00ACC1), // Light Teal (Start color)
                  Color(0xFF3F51B5), // Dark Blue (End color)
                ],
                // When currentStop is 0, the radius is small, looking like a point.
                // As it approaches 1, the radius expands to reveal the full gradient.
                stops: [0.0, 1.0], 
              ),
            ),
            child: Stack(
              children: [
                // Logo
                const AppLogo(size: 80),
                
                // Center text + spinner
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "DBTI Attendance System",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Reusable Logo Widget - Extracted from source
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Image.asset(
          "assets/images/dbti_logo.png",
          height: size,
        ),
      ),
    );
  }
}