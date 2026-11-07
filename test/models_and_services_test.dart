import 'package:flutter_test/flutter_test.dart';
import 'package:emma_drive/models/user_model.dart';
import 'package:emma_drive/models/drive_model.dart';
import 'package:emma_drive/models/drive_submission_model.dart';
import 'package:emma_drive/services/mock_data_service.dart';

void main() {
  group('Emma Models & Services Unit Tests', () {
    test('UserModel serialization and role mapping', () {
      final participant = UserModel(
        uid: 'user_1',
        name: 'Alice',
        email: 'alice@example.com',
        phone: '+1 555-1234',
        role: UserRole.participant,
      );

      final map = participant.toMap();
      expect(map['role'], 'participant');
      expect(map['name'], 'Alice');

      final deserialized = UserModel.fromMap('user_1', map);
      expect(deserialized.role, UserRole.participant);
      expect(deserialized.name, 'Alice');

      final manufacturer = UserModel(
        uid: 'mfg_1',
        name: 'EcoFactory',
        email: 'ops@ecofactory.com',
        phone: '+1 555-9876',
        role: UserRole.manufacturer,
      );
      expect(manufacturer.role.displayName, 'Manufacturer');
    });

    test('DriveModel target and collected weight progress', () {
      final drive = DriveModel(
        driveId: 'DRIVE_TEST',
        title: 'Battery Reclamation Drive',
        description: 'Safe collection of heavy industrial batteries',
        manufacturerId: 'mfg_1',
        manufacturerName: 'EcoFactory',
        location: 'Civic Center Gate 2',
        date: DateTime.now().add(const Duration(days: 2)),
        acceptedCategories: ['Batteries', 'UPS'],
        targetWeightKg: 1000.0,
        currentWeightKg: 250.0,
      );

      expect(drive.targetWeightKg, 1000.0);
      expect(drive.currentWeightKg, 250.0);

      final updated = drive.copyWith(currentWeightKg: 500.0);
      expect(updated.currentWeightKg, 500.0);
    });

    test('DriveSubmissionModel weight verification state', () {
      final submission = DriveSubmissionModel(
        submissionId: 'SUB_TEST',
        driveId: 'DRIVE_TEST',
        participantUid: 'user_1',
        participantName: 'Alice',
        participantEmail: 'alice@example.com',
        participantPhone: '+1 555-1234',
        itemImageUrl: 'https://example.com/photo.jpg',
        category: 'Laptops',
        status: 'submitted',
      );

      expect(submission.isVerified, false);
      expect(submission.weightKg, isNull);

      final verified = submission.copyWith(
        weightKg: 14.5,
        status: 'verified',
        verifiedAt: DateTime.now(),
        verifiedBy: 'EcoFactory Inspector',
      );

      expect(verified.isVerified, true);
      expect(verified.weightKg, 14.5);
      expect(verified.verifiedBy, 'EcoFactory Inspector');
    });

    test('MockDataService seed data and live stream verification', () async {
      final service = MockDataService.instance;
      final drives = await service.streamDrives().first;
      expect(drives.isNotEmpty, true);

      final submissions = await service.streamSubmissions().first;
      expect(submissions.isNotEmpty, true);

      final initialLength = submissions.length;
      final newSub = DriveSubmissionModel(
        submissionId: 'SUB_NEW_99',
        driveId: drives.first.driveId,
        participantUid: 'user_new',
        participantName: 'New User',
        participantEmail: 'new@example.com',
        participantPhone: '+1 555-9999',
        itemImageUrl: 'data:image/jpeg;base64,sample',
        category: 'Batteries',
        status: 'submitted',
      );

      await service.addSubmission(newSub);
      final updatedList = await service.streamSubmissions().first;
      expect(updatedList.length, initialLength + 1);

      // Verify weight
      await service.updateVerifiedWeight(
        submissionId: 'SUB_NEW_99',
        weightKg: 8.2,
        verifiedBy: 'EcoFactory',
      );

      final verifiedList = await service.streamSubmissions().first;
      final targetSub = verifiedList.firstWhere((s) => s.submissionId == 'SUB_NEW_99');
      expect(targetSub.isVerified, true);
      expect(targetSub.weightKg, 8.2);
    });
  });
}
