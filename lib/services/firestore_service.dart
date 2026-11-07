import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/drive_model.dart';
import '../models/drive_submission_model.dart';
import 'storage_service.dart';
import 'mock_data_service.dart';
import 'webhook_service.dart';

class FirestoreService {
  final FirebaseFirestore? _firestore;
  final StorageService _storageService;
  final MockDataService _mockData = MockDataService.instance;
  final Uuid _uuid = const Uuid();

  FirestoreService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore,
        _storageService = storageService ?? StorageService();

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty && _firestore != null;

  /// Stream of all active/upcoming drives
  Stream<List<DriveModel>> streamDrives() {
    if (isFirebaseAvailable) {
      try {
        return _firestore!
            .collection('drives')
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                return _mockData.drives;
              }
              return snapshot.docs
                  .map((doc) => DriveModel.fromMap(doc.id, doc.data()))
                  .toList();
            });
      } catch (e) {
        // Fallback to mock stream
      }
    }
    return _mockData.streamDrives();
  }

  /// Stream of all registered participant submissions for a given drive
  Stream<List<DriveSubmissionModel>> streamSubmissionsForDrive(String driveId) {
    if (isFirebaseAvailable) {
      try {
        return _firestore!
            .collection('drive_submissions')
            .where('driveId', isEqualTo: driveId)
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                return _mockData.submissions.where((s) => s.driveId == driveId).toList();
              }
              return snapshot.docs
                  .map((doc) => DriveSubmissionModel.fromMap(doc.id, doc.data()))
                  .toList();
            });
      } catch (e) {
        // Fallback to mock stream
      }
    }
    return _mockData.streamSubmissionsForDrive(driveId);
  }

  /// Stream of submissions made by a specific participant
  Stream<List<DriveSubmissionModel>> streamUserSubmissions(String uid) {
    if (isFirebaseAvailable) {
      try {
        return _firestore!
            .collection('drive_submissions')
            .where('participantUid', isEqualTo: uid)
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                return _mockData.submissions.where((s) => s.participantUid == uid).toList();
              }
              return snapshot.docs
                  .map((doc) => DriveSubmissionModel.fromMap(doc.id, doc.data()))
                  .toList();
            });
      } catch (e) {
        // Fallback to mock stream
      }
    }
    return _mockData.streamUserSubmissions(uid);
  }

  /// Stream all submissions across all drives (for Developer Analytics Hub)
  Stream<List<DriveSubmissionModel>> streamAllSubmissions() {
    if (isFirebaseAvailable) {
      try {
        return _firestore!
            .collection('drive_submissions')
            .orderBy('submittedAt', descending: true)
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                return _mockData.submissions;
              }
              return snapshot.docs
                  .map((doc) => DriveSubmissionModel.fromMap(doc.id, doc.data()))
                  .toList();
            });
      } catch (e) {
        // Fallback to mock stream
      }
    }
    return _mockData.streamSubmissions();
  }

  /// Participant submits a waste item for an upcoming drive
  Future<DriveSubmissionModel> submitDriveRegistration({
    required String driveId,
    required String participantUid,
    required String participantName,
    required String participantEmail,
    required String participantPhone,
    required String category,
    required String notes,
    required XFile imageFile,
  }) async {
    final submissionId = 'SUB_${_uuid.v4().substring(0, 8).toUpperCase()}';

    // 1. Upload photo to Firebase Storage (or encode data URL)
    final imageUrl = await _storageService.uploadWasteItemImage(
      driveId: driveId,
      submissionId: submissionId,
      imageFile: imageFile,
    );

    // 2. Prepare submission document
    final submission = DriveSubmissionModel(
      submissionId: submissionId,
      driveId: driveId,
      participantUid: participantUid,
      participantName: participantName,
      participantEmail: participantEmail,
      participantPhone: participantPhone,
      itemImageUrl: imageUrl,
      category: category,
      notes: notes,
      weightKg: null,
      status: 'submitted',
      submittedAt: DateTime.now(),
    );

    // 3. Save to Firestore 'drive_submissions'
    if (isFirebaseAvailable) {
      try {
        await _firestore!
            .collection('drive_submissions')
            .doc(submissionId)
            .set(submission.toMap());
      } catch (e) {
        // Fall through to mock store
      }
    }

    // Always keep mock store in sync for real-time reactivity
    await _mockData.addSubmission(submission);

    // 4. Send n8n webhook notification directly (100% Free - Works on Spark without Blaze)
    WebhookService.instance.sendRegistrationSuccess(
      submissionId: submissionId,
      participantName: participantName,
      phone: participantPhone,
      driveTitle: driveId,
    );

    return submission;
  }

  /// Manufacturer enters and logs verified weight
  Future<void> updateVerifiedWeight({
    required String submissionId,
    required double weightKg,
    required String verifiedBy,
  }) async {
    if (isFirebaseAvailable) {
      try {
        await _firestore!.collection('drive_submissions').doc(submissionId).update({
          'weightKg': weightKg,
          'status': 'verified',
          'verifiedAt': DateTime.now().toIso8601String(),
          'verifiedBy': verifiedBy,
        });
      } catch (e) {
        // Fall through to mock store
      }
    }

    // Also update mock in-memory store
    await _mockData.updateVerifiedWeight(
      submissionId: submissionId,
      weightKg: weightKg,
      verifiedBy: verifiedBy,
    );

    // Send n8n verified webhook notification directly (100% Free)
    try {
      final sub = _mockData.submissions.firstWhere(
        (s) => s.submissionId == submissionId,
        orElse: () => DriveSubmissionModel(
          submissionId: submissionId,
          driveId: '',
          participantUid: '',
          participantName: 'Participant',
          participantEmail: '',
          participantPhone: '',
          itemImageUrl: '',
          category: '',
          notes: '',
          status: 'verified',
          submittedAt: DateTime.now(),
        ),
      );

      WebhookService.instance.sendSubmissionVerified(
        submissionId: submissionId,
        participantName: sub.participantName,
        phone: sub.participantPhone,
        driveTitle: sub.driveId,
        weightKg: weightKg,
      );
    } catch (_) {}
  }

  /// Seeds sample drives into Firestore if empty so all 100 participants see upcoming drives
  Future<void> seedInitialDrivesIfEmpty() async {
    final firestore = _firestore;
    if (!isFirebaseAvailable || firestore == null) return;
    try {
      final snap = await firestore.collection('drives').limit(1).get();
      if (snap.docs.isEmpty) {
        for (final drive in _mockData.drives) {
          await firestore.collection('drives').doc(drive.driveId).set(drive.toMap());
        }
      }
    } catch (_) {
      // Ignored if rules not yet activated
    }
  }
}
