import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../widgets/arcade_progress_bar.dart';
import 'main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Simulated quick load progress bar
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _loadingProgress += 0.035;
        if (_loadingProgress >= 1.0) {
          _loadingProgress = 1.0;
          timer.cancel();
          _navigateToHome();
        }
      });
    });
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainNavigationShell(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Cute Piggy Roman Coin Logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowDefault,
                            offset: Offset(0, 8),
                            blurRadius: 0, // Flat 3D arcade shadow
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.gold,
                            child: const Icon(
                              Icons.savings_rounded,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: const [
                      Text(
                        'MONETA',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: AppColors.gold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PORCRCVS • MONETA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'บันทึกการเงินด้วยการปัดสลิป • ไร้รอยต่อ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Playful Arcade Loading Progress Bar
                Column(
                  children: [
                    SizedBox(
                      width: 140,
                      child: ArcadeProgressBar(
                        value: _loadingProgress.clamp(0.0, 1.0),
                        height: 8,
                        progressColor: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'กำลังโหลดข้อมูล...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
