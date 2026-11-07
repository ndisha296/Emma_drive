import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? weightKg;

  const StatusBadge({
    super.key,
    required this.status,
    this.weightKg,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status.toLowerCase() == 'verified';
    final Color badgeColor = isVerified ? AppTheme.statusVerified : AppTheme.statusPending;
    final IconData icon = isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded;
    final String label = isVerified
        ? (weightKg != null ? 'Verified: ${weightKg!.toStringAsFixed(1)} kg' : 'Verified')
        : 'Pending Weight';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
