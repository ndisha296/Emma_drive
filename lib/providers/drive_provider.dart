import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/drive_model.dart';
import '../models/drive_submission_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  if (Firebase.apps.isNotEmpty) {
    try {
      return FirestoreService(
        firestore: FirebaseFirestore.instance,
        storageService: storage,
      );
    } catch (_) {}
  }
  return FirestoreService(storageService: storage);
});

/// Real-time stream of all waste drives
final drivesStreamProvider = StreamProvider<List<DriveModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  firestore.seedInitialDrivesIfEmpty();
  return firestore.streamDrives();
});

/// Currently selected drive ID (defaults to 'DRIVE_456')
final selectedDriveIdProvider = StateProvider<String>((ref) => 'DRIVE_456');

/// Active selected DriveModel
final selectedDriveProvider = Provider<DriveModel?>((ref) {
  final drivesAsync = ref.watch(drivesStreamProvider);
  final selectedId = ref.watch(selectedDriveIdProvider);

  return drivesAsync.maybeWhen(
    data: (drives) => drives.firstWhere(
      (d) => d.driveId == selectedId,
      orElse: () => drives.isNotEmpty ? drives.first : throw Exception('No drives available'),
    ),
    orElse: () => null,
  );
});

/// Real-time stream of submissions for a given drive
final driveSubmissionsProvider =
    StreamProvider.family<List<DriveSubmissionModel>, String>((ref, driveId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamSubmissionsForDrive(driveId);
});

/// Real-time stream of submissions made by the currently logged-in user
final userSubmissionsProvider = StreamProvider<List<DriveSubmissionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamUserSubmissions(user.uid);
});

/// Filter state for manufacturer list view: 'all' | 'submitted' | 'verified'
final manufacturerFilterProvider = StateProvider<String>((ref) => 'all');

/// Filtered submissions for the selected drive in the Manufacturer view
final filteredDriveSubmissionsProvider = Provider<List<DriveSubmissionModel>>((ref) {
  final driveId = ref.watch(selectedDriveIdProvider);
  final submissionsAsync = ref.watch(driveSubmissionsProvider(driveId));
  final filter = ref.watch(manufacturerFilterProvider);

  return submissionsAsync.maybeWhen(
    data: (submissions) {
      if (filter == 'all') return submissions;
      return submissions.where((s) => s.status == filter).toList();
    },
    orElse: () => [],
  );
});

/// Controller to perform drive submission and weight verification
class DriveOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestore;

  DriveOperationsNotifier(this._firestore) : super(const AsyncValue.data(null));

  Future<DriveSubmissionModel> submitRegistration({
    required String driveId,
    required String participantUid,
    required String participantName,
    required String participantEmail,
    required String participantPhone,
    required String category,
    required String notes,
    required XFile imageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final submission = await _firestore.submitDriveRegistration(
        driveId: driveId,
        participantUid: participantUid,
        participantName: participantName,
        participantEmail: participantEmail,
        participantPhone: participantPhone,
        category: category,
        notes: notes,
        imageFile: imageFile,
      );
      state = const AsyncValue.data(null);
      return submission;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> verifyWeight({
    required String submissionId,
    required double weightKg,
    required String verifiedBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.updateVerifiedWeight(
        submissionId: submissionId,
        weightKg: weightKg,
        verifiedBy: verifiedBy,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final driveOperationsProvider =
    StateNotifierProvider<DriveOperationsNotifier, AsyncValue<void>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return DriveOperationsNotifier(firestore);
});
