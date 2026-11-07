import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drive_provider.dart';
import '../../widgets/emma_logo_widget.dart';
import '../../widgets/item_image_viewer.dart';
import '../../widgets/status_badge.dart';
import '../auth/auth_screen.dart';
import '../manufacturer/manufacturer_dashboard_screen.dart';
import '../developer/developer_analytics_screen.dart';
import 'participant_registration_dialog.dart';

class ParticipantHomeScreen extends ConsumerWidget {
  const ParticipantHomeScreen({super.key});

  void _openRegistrationDialog(BuildContext context, String driveId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParticipantRegistrationDialog(driveId: driveId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final drivesAsync = ref.watch(drivesStreamProvider);
    final userSubmissionsAsync = ref.watch(userSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const EmmaLogoWidget(size: 32, showText: false, animate: false),
            const SizedBox(width: 10),
            Text(
              'Emma Drive',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Switch to Manufacturer button for effortless demo navigation
          IconButton(
            tooltip: 'Switch to Manufacturer View',
            icon: const Icon(Icons.precision_manufacturing_outlined, color: AppTheme.accentOrange),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).switchRole(UserRole.manufacturer);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ManufacturerDashboardScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Developer & Analytics Hub',
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeveloperAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(drivesStreamProvider);
          ref.invalidate(userSubmissionsProvider);
        },
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13231B), Color(0xFF131B2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.darkCardElevated,
                          backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.startsWith('http')
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null || !user!.profileImageUrl!.startsWith('http')
                              ? const Icon(Icons.person_rounded, color: AppTheme.primaryGreen, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              Text(
                                user?.name ?? 'Eco Participant',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textLight,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'COMMUNITY PARTICIPANT',
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.primaryGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: AppTheme.darkCardBorder),
                    const SizedBox(height: 12),

                    // User Eco Impact Summary
                    userSubmissionsAsync.when(
                      data: (submissions) {
                        final verifiedSubmissions = submissions.where((s) => s.isVerified);
                        final totalUserKg = verifiedSubmissions.fold<double>(
                          0.0,
                          (sum, s) => sum + (s.weightKg ?? 0.0),
                        );
                        final userCo2 = totalUserKg * 1.44;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniImpactMetric(
                              '${submissions.length}',
                              'Registered',
                              Icons.assignment_turned_in_outlined,
                              AppTheme.statusUpcoming,
                            ),
                            Container(width: 1, height: 36, color: AppTheme.darkCardBorder),
                            _buildMiniImpactMetric(
                              '${totalUserKg.toStringAsFixed(1)} kg',
                              'Verified Weight',
                              Icons.scale_rounded,
                              AppTheme.primaryGreen,
                            ),
                            Container(width: 1, height: 36, color: AppTheme.darkCardBorder),
                            _buildMiniImpactMetric(
                              '${userCo2.toStringAsFixed(1)} kg',
                              'CO2 Saved',
                              Icons.eco_rounded,
                              AppTheme.accentOrange,
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                        ),
                      ),
                      error: (error, stack) => const SizedBox(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Upcoming Waste Drives Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Waste Drives',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    'Drop-Off Ready',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              drivesAsync.when(
                data: (drives) {
                  if (drives.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkCardBorder),
                      ),
                      child: Center(
                        child: Text(
                          'No active drives scheduled currently.',
                          style: GoogleFonts.outfit(color: AppTheme.textMuted),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: drives.map((drive) {
                      final progress = (drive.currentWeightKg / drive.targetWeightKg).clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.darkCardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        drive.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.factory_rounded, size: 14, color: AppTheme.accentOrange),
                                          const SizedBox(width: 4),
                                          Text(
                                            drive.manufacturerName,
                                            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.accentOrange),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    DateFormat('MMM dd').format(drive.date),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              drive.description,
                              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 14),

                            // Location
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    drive.location,
                                    style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Progress to Target
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress: ${drive.currentWeightKg.toStringAsFixed(1)} kg collected',
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  'Target: ${drive.targetWeightKg.toStringAsFixed(0)} kg',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: AppTheme.darkCardElevated,
                                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Register Action Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openRegistrationDialog(context, drive.driveId),
                                icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
                                label: const Text('Register for Drive & Snap Photo'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
                error: (e, _) => Text('Error loading drives: $e'),
              ),
              const SizedBox(height: 24),

              // My Submissions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Submissions',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    'Live Verification Track',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              userSubmissionsAsync.when(
                data: (submissions) {
                  if (submissions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkCardBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'No items registered yet',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Click "Register for Drive" above to photograph and bring your recyclable waste.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: submissions.map((sub) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.darkCardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 75,
                                height: 75,
                                child: ItemImageViewer(
                                  imageUrl: sub.itemImageUrl,
                                  width: 75,
                                  height: 75,
                                  title: sub.category,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sub.category,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ),
                                      StatusBadge(
                                        status: sub.status,
                                        weightKg: sub.weightKg,
                                      ),
                                    ],
                                  ),
                                  if (sub.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      sub.notes,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Submitted on ${DateFormat('MMM dd, yyyy • hh:mm a').format(sub.submittedAt)}',
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (e, _) => Text('Error loading submissions: $e'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniImpactMetric(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
