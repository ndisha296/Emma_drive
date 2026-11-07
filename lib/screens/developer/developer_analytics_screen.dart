import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/drive_submission_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/drive_provider.dart';
import '../../widgets/emma_logo_widget.dart';
import '../../widgets/item_image_viewer.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class DeveloperAnalyticsScreen extends ConsumerStatefulWidget {
  const DeveloperAnalyticsScreen({super.key});

  @override
  ConsumerState<DeveloperAnalyticsScreen> createState() =>
      _DeveloperAnalyticsScreenState();
}

class _DeveloperAnalyticsScreenState extends ConsumerState<DeveloperAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(globalImpactMetricsProvider);
    final allSubmissionsAsync = ref.watch(allSubmissionsStreamProvider);
    final drivesAsync = ref.watch(drivesStreamProvider);
    final isFirebase = ref.watch(firestoreServiceProvider).isFirebaseAvailable;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const EmmaLogoWidget(size: 28, showText: false, animate: false),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developer & Analytics Hub',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Centralized Real-Time Data Stream',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isFirebase
                  ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                  : AppTheme.statusUpcoming.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFirebase ? AppTheme.primaryGreen : AppTheme.statusUpcoming,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_done_rounded,
                  size: 14,
                  color: isFirebase ? AppTheme.primaryGreen : AppTheme.statusUpcoming,
                ),
                const SizedBox(width: 4),
                Text(
                  isFirebase ? 'Firebase Live' : 'Demo Stream Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFirebase ? AppTheme.primaryGreen : AppTheme.statusUpcoming,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Impact Metrics'),
            Tab(icon: Icon(Icons.photo_library_rounded, size: 20), text: 'Photo Stream'),
            Tab(icon: Icon(Icons.data_object_rounded, size: 20), text: 'Firestore Docs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImpactTab(metrics, allSubmissionsAsync),
          _buildPhotoStreamTab(allSubmissionsAsync),
          _buildFirestoreDocsTab(allSubmissionsAsync, drivesAsync),
        ],
      ),
    );
  }

  Widget _buildImpactTab(ImpactMetrics metrics, AsyncValue<List<DriveSubmissionModel>> submissionsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF132A1F), Color(0xFF131B2A)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const EmmaLogoWidget(size: 64, showText: false, animate: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total E-Waste Diverted',
                        style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      Text(
                        '${metrics.totalWeightKg} kg Recycled',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From ${metrics.uniqueParticipants} verified participants across all community drives.',
                        style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'CO2 Offset',
                  value: '${metrics.co2AvoidedKg}',
                  unit: 'kg eq',
                  icon: Icons.cloud_outlined,
                  accentColor: AppTheme.statusUpcoming,
                  subtitle: '1.44 kg CO2 / kg e-waste',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Trees Equivalent',
                  value: '${metrics.treesEquivalent}',
                  unit: 'trees',
                  icon: Icons.park_outlined,
                  accentColor: AppTheme.primaryGreen,
                  subtitle: 'Carbon absorption eq',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Landfill Saved',
                  value: '${metrics.landfillSpaceSavedM3}',
                  unit: 'm³',
                  icon: Icons.delete_sweep_outlined,
                  accentColor: AppTheme.accentOrange,
                  subtitle: 'Toxic metals diverted',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Verified Items',
                  value: '${metrics.verifiedCount} / ${metrics.totalSubmissions}',
                  unit: 'items',
                  icon: Icons.fact_check_outlined,
                  accentColor: AppTheme.statusVerified,
                  subtitle: '${metrics.pendingCount} pending scale check',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            'Material Distribution Breakdown',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textLight),
          ),
          const SizedBox(height: 12),

          if (metrics.categoryWeights.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Center(
                child: Text(
                  'No verified weights logged yet to generate material distribution.',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Column(
                children: metrics.categoryWeights.entries.map((entry) {
                  final ratio = metrics.totalWeightKg > 0
                      ? (entry.value / metrics.totalWeightKg).clamp(0.0, 1.0)
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                              ),
                            ),
                            Text(
                              '${entry.value.toStringAsFixed(1)} kg (${(ratio * 100).toStringAsFixed(0)}%)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: AppTheme.darkCardElevated,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoStreamTab(AsyncValue<List<DriveSubmissionModel>> submissionsAsync) {
    return submissionsAsync.when(
      data: (submissions) {
        if (submissions.isEmpty) {
          return Center(
            child: Text(
              'No photo submissions registered yet.',
              style: GoogleFonts.outfit(color: AppTheme.textMuted),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final s = submissions[index];
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: ItemImageViewer(
                        imageUrl: s.itemImageUrl,
                        title: '${s.category} • ${s.participantName}',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                s.participantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ),
                            StatusBadge(status: s.status, weightKg: s.weightKg),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFirestoreDocsTab(
    AsyncValue<List<DriveSubmissionModel>> submissionsAsync,
    AsyncValue<List<dynamic>> drivesAsync,
  ) {
    return submissionsAsync.when(
      data: (submissions) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Live Firestore Collections Stream',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textLight),
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time collection snapshot stream (ordered by submittedAt DESC):',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),

            ...submissions.map((sub) {
              final jsonStr = const JsonEncoder.withIndent('  ').convert(sub.toMap());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'drive_submissions / ${sub.submissionId}',
                          style: GoogleFonts.firaCode(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        StatusBadge(status: sub.status, weightKg: sub.weightKg),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCardElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        jsonStr,
                        style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
