import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class EmmaLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final bool animate;

  const EmmaLogoWidget({
    super.key,
    this.size = 140,
    this.showText = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.25),
            blurRadius: size * 0.25,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // High-fidelity fallback vector if asset is loading or missing
            return Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.eco_rounded,
                  color: AppTheme.primaryGreen,
                  size: size * 0.55,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (animate) {
      logoCore = logoCore
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 2500.ms,
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          )
          .scaleXY(
            begin: 0.98,
            end: 1.02,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    if (!showText) {
      return logoCore;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoCore,
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EM',
              style: GoogleFonts.outfit(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppTheme.accentOrange,
              ),
            ),
            Text(
              'MA',
              style: GoogleFonts.outfit(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppTheme.accentOrangeLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Text(
            'EXPIRED MACHINE MANAGEMENT APP',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
