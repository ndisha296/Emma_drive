import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/drive_submission_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drive_provider.dart';
import '../../widgets/emma_logo_widget.dart';
import '../../widgets/item_image_viewer.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../auth/auth_screen.dart';
import '../participant/participant_home_screen.dart';
import '../developer/developer_analytics_screen.dart';
import 'weight_entry_dialog.dart';

class ManufacturerDashboardScreen extends ConsumerWidget {
  const ManufacturerDashboardScreen({super.key});

  void _openWeightEntryModal(BuildContext context, DriveSubmissionModel submission) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WeightEntryDialog(submission: submission),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final drivesAsync = ref.watch(drivesStreamProvider);
    final selectedDriveId = ref.watch(selectedDriveIdProvider);
    final selectedDrive = ref.watch(selectedDriveProvider);
    final submissions = ref.watch(filteredDriveSubmissionsProvider);
    final allSubmissionsForDriveAsync = ref.watch(driveSubmissionsProvider(selectedDriveId));
    final activeFilter = ref.watch(manufacturerFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const EmmaLogoWidget(size: 32, showText: false, animate: false),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manufacturer Hub',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  user?.name ?? 'Revive Tech Recycling',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.accentOrange),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Switch to Participant View for smooth demo testing
          IconButton(
            tooltip: 'Switch to Participant View',
            icon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).switchRole(UserRole.participant);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ParticipantHomeScreen()),
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
          ref.invalidate(driveSubmissionsProvider(selectedDriveId));
        },
        color: AppTheme.accentOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drive Selector Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE WASTE DRIVE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'LIVE SYNC',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    drivesAsync.when(
                      data: (drives) {
                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: drives.any((d) => d.driveId == selectedDriveId)
                              ? selectedDriveId
                              : (drives.isNotEmpty ? drives.first.driveId : null),
                          dropdownColor: AppTheme.darkCardElevated,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            prefixIcon: Icon(Icons.location_city_rounded, color: AppTheme.accentOrange),
                          ),
                          items: drives
                              .map((d) => DropdownMenuItem(
                                    value: d.driveId,
                                    child: Text(
                                      '${d.title} (${d.driveId})',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.textLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(selectedDriveIdProvider.notifier).state = val;
                            }
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppTheme.accentOrange),
                      error: (error, stack) => const Text('Error loading drives list'),
                    ),
                    if (selectedDrive != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              selectedDrive.location,
                              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM dd').format(selectedDrive.date),
                            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Overview Stats Grid
              allSubmissionsForDriveAsync.when(
                data: (allSubs) {
                  final verifiedSubs = allSubs.where((s) => s.isVerified);
                  final pendingSubs = allSubs.where((s) => !s.isVerified);
                  final totalWeight = verifiedSubs.fold<double>(
                    0.0,
                    (sum, s) => sum + (s.weightKg ?? 0.0),
                  );

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Verified Weight',
                              value: totalWeight.toStringAsFixed(1),
                              unit: 'kg',
                              icon: Icons.scale_rounded,
                              accentColor: AppTheme.primaryGreen,
                              subtitle: 'Target: ${selectedDrive?.targetWeightKg.toStringAsFixed(0) ?? 500} kg',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Pending Weights',
                              value: '${pendingSubs.length}',
                              unit: 'items',
                              icon: Icons.hourglass_top_rounded,
                              accentColor: AppTheme.statusPending,
                              subtitle: 'Action required',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Participants',
                              value: '${allSubs.map((s) => s.participantEmail).toSet().length}',
                              unit: 'users',
                              icon: Icons.people_alt_outlined,
                              accentColor: AppTheme.statusUpcoming,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Completed',
                              value: '${verifiedSubs.length}',
                              unit: 'done',
                              icon: Icons.verified_rounded,
                              accentColor: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (error, stack) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Filter Chips Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participant Submissions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        '${submissions.length} Total',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(ref, 'all', 'All Submissions', activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip(ref, 'submitted', 'Pending Weight', activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip(ref, 'verified', 'Verified & Logged', activeFilter),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Participant List
              if (submissions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkCardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, color: AppTheme.textMuted, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'No submissions matching filter',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registered participants for this drive will appear here in real-time.',
                          style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final sub = submissions[index];
                    return _buildParticipantCard(context, sub);
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String key, String label, String active) {
    final isSelected = active == key;
    return GestureDetector(
      onTap: () => ref.read(manufacturerFilterProvider.notifier).state = key,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.darkCardElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.darkCardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCard(BuildContext context, DriveSubmissionModel sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: sub.isVerified ? AppTheme.darkCardBorder : AppTheme.statusPending.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Participant info & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.darkCardElevated,
                      child: Text(
                        sub.participantName.isNotEmpty ? sub.participantName[0].toUpperCase() : 'P',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.participantName,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                sub.participantPhone,
                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: sub.status, weightKg: sub.weightKg),
            ],
          ),
          const SizedBox(height: 14),

          // Uploaded Photo & Item Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: ItemImageViewer(
                    imageUrl: sub.itemImageUrl,
                    width: 90,
                    height: 90,
                    title: '${sub.category} • ${sub.participantName}',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCardElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sub.category,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreenLight,
                        ),
                      ),
                    ),
                    if (sub.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        sub.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${sub.participantEmail}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    Text(
                      'Submitted ${DateFormat('MMM dd • hh:mm a').format(sub.submittedAt)}',
                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.darkCardBorder, height: 1),
          const SizedBox(height: 12),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (sub.isVerified)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Verified: ${sub.weightKg?.toStringAsFixed(1)} kg',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.statusPending, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Pending scale check',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.statusPending,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openWeightEntryModal(context, sub),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sub.isVerified ? AppTheme.darkCardElevated : AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(
                  sub.isVerified ? Icons.edit_note_rounded : Icons.scale_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  sub.isVerified ? 'Update Weight' : 'Log & Verify Weight',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
