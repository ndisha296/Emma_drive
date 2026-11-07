import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/emma_logo_widget.dart';
import 'auth/auth_screen.dart';
import 'participant/participant_home_screen.dart';
import 'manufacturer/manufacturer_dashboard_screen.dart';
import 'developer/developer_analytics_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Elegant splash presentation delay
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      if (currentUser.role == UserRole.manufacturer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ManufacturerDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParticipantHomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const AuthScreen(),
          transitionsBuilder: (context, animation, secAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              ),
            ).animate().fadeIn(duration: 1200.ms),
          ),

          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentOrange.withValues(alpha: 0.12),
              ),
            ).animate().fadeIn(duration: 1400.ms),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmmaLogoWidget(size: 170, showText: true, animate: true),
                const SizedBox(height: 32),
                Text(
                  'Community-Driven Waste Drives & Upcycling',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 48),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.darkCardBorder,
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),

          // Bottom quick developer skip
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DeveloperAnalyticsScreen()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 16, color: AppTheme.textMuted),
                label: Text(
                  'Open Developer & Analytics Hub',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ),
        ],
      ),
    );
  }
}
