import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drive_submission_model.dart';
import 'drive_provider.dart';

/// Stream of all submissions across all drives
final allSubmissionsStreamProvider = StreamProvider<List<DriveSubmissionModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamAllSubmissions();
});

class ImpactMetrics {
  final double totalWeightKg;
  final int totalSubmissions;
  final int verifiedCount;
  final int pendingCount;
  final int uniqueParticipants;
  final double co2AvoidedKg;
  final double treesEquivalent;
  final double landfillSpaceSavedM3;
  final Map<String, double> categoryWeights;

  const ImpactMetrics({
    required this.totalWeightKg,
    required this.totalSubmissions,
    required this.verifiedCount,
    required this.pendingCount,
    required this.uniqueParticipants,
    required this.co2AvoidedKg,
    required this.treesEquivalent,
    required this.landfillSpaceSavedM3,
    required this.categoryWeights,
  });

  static ImpactMetrics initial() {
    return const ImpactMetrics(
      totalWeightKg: 0.0,
      totalSubmissions: 0,
      verifiedCount: 0,
      pendingCount: 0,
      uniqueParticipants: 0,
      co2AvoidedKg: 0.0,
      treesEquivalent: 0.0,
      landfillSpaceSavedM3: 0.0,
      categoryWeights: {},
    );
  }
}

final globalImpactMetricsProvider = Provider<ImpactMetrics>((ref) {
  final submissionsAsync = ref.watch(allSubmissionsStreamProvider);

  return submissionsAsync.maybeWhen(
    data: (submissions) {
      double totalKg = 0.0;
      int verified = 0;
      int pending = 0;
      final Set<String> participants = {};
      final Map<String, double> categories = {};

      for (final s in submissions) {
        participants.add(s.participantUid.isNotEmpty ? s.participantUid : s.participantEmail);
        if (s.isVerified && s.weightKg != null) {
          totalKg += s.weightKg!;
          verified++;
          categories[s.category] = (categories[s.category] ?? 0.0) + s.weightKg!;
        } else {
          pending++;
        }
      }

      // Ecological impact benchmarks:
      // ~1.44 kg CO2 reduction per 1 kg e-waste diverted from incineration/landfills
      final co2Avoided = totalKg * 1.44;
      // 1 mature tree absorbs ~21.8 kg CO2 per year
      final trees = co2Avoided / 21.8;
      // ~0.0018 m³ landfill volume saved per kg
      final landfill = totalKg * 0.0018;

      return ImpactMetrics(
        totalWeightKg: double.parse(totalKg.toStringAsFixed(1)),
        totalSubmissions: submissions.length,
        verifiedCount: verified,
        pendingCount: pending,
        uniqueParticipants: participants.length,
        co2AvoidedKg: double.parse(co2Avoided.toStringAsFixed(1)),
        treesEquivalent: double.parse(trees.toStringAsFixed(1)),
        landfillSpaceSavedM3: double.parse(landfill.toStringAsFixed(2)),
        categoryWeights: categories,
      );
    },
    orElse: () => ImpactMetrics.initial(),
  );
});
