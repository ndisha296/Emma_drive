import 'dart:async';
import '../models/user_model.dart';
import '../models/drive_model.dart';
import '../models/drive_submission_model.dart';

class MockDataService {
  static final MockDataService instance = MockDataService._internal();
  MockDataService._internal() {
    _initializeSeedData();
  }

  final StreamController<List<DriveModel>> _drivesController =
      StreamController<List<DriveModel>>.broadcast();
  final StreamController<List<DriveSubmissionModel>> _submissionsController =
      StreamController<List<DriveSubmissionModel>>.broadcast();

  final List<DriveModel> _drives = [];
  final List<DriveSubmissionModel> _submissions = [];
  final Map<String, UserModel> _users = {};

  void _initializeSeedData() {
    // Seed Users
    final demoParticipant = UserModel(
      uid: 'user_jane_doe',
      name: 'Jane Doe',
      email: 'jane@example.com',
      phone: '+1 (555) 234-5678',
      role: UserRole.participant,
      profileImageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    final demoManufacturer = UserModel(
      uid: 'mfg_revive_tech',
      name: 'Revive Tech Recycling Co.',
      email: 'operations@revivetech.com',
      phone: '+1 (555) 987-6543',
      role: UserRole.manufacturer,
      profileImageUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    _users[demoParticipant.uid] = demoParticipant;
    _users[demoManufacturer.uid] = demoManufacturer;

    // Seed Drives
    final drive1 = DriveModel(
      driveId: 'DRIVE_456',
      title: 'Central Tech & E-Waste Drive',
      description: 'Bring expired laptops, motherboards, batteries, and appliances for high-value metal recovery and safe disposal.',
      manufacturerId: 'mfg_revive_tech',
      manufacturerName: 'Revive Tech Recycling Co.',
      location: 'Central Park East Community Center',
      date: DateTime.now().add(const Duration(days: 4)),
      acceptedCategories: ['Laptops & PCs', 'Monitors & TVs', 'Lithium Batteries', 'Small Appliances'],
      targetWeightKg: 750.0,
      currentWeightKg: 138.4,
      status: 'active',
    );

    final drive2 = DriveModel(
      driveId: 'DRIVE_789',
      title: 'Expired Machine & Circuit Reclamation',
      description: 'Specialized industrial upcycling drive for scrap electric machinery, motor coils, and telecom equipment.',
      manufacturerId: 'mfg_revive_tech',
      manufacturerName: 'Revive Tech Recycling Co.',
      location: 'Metro Logistics Hub - Bay 3',
      date: DateTime.now().add(const Duration(days: 11)),
      acceptedCategories: ['Heavy Electronics', 'Motor Windings', 'Cables & Wiring', 'Telecom Gear'],
      targetWeightKg: 1500.0,
      currentWeightKg: 320.0,
      status: 'upcoming',
    );

    _drives.addAll([drive1, drive2]);

    // Seed Submissions
    _submissions.addAll([
      DriveSubmissionModel(
        submissionId: 'SUB_001',
        driveId: 'DRIVE_456',
        participantUid: 'user_jane_doe',
        participantName: 'Jane Doe',
        participantEmail: 'jane@example.com',
        participantPhone: '+1 (555) 234-5678',
        itemImageUrl: 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=500',
        category: 'Laptops & PCs',
        notes: '2 Old ThinkPad laptops, swollen batteries removed beforehand.',
        weightKg: 5.8,
        status: 'verified',
        submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
        verifiedAt: DateTime.now().subtract(const Duration(hours: 3)),
        verifiedBy: 'Revive Tech Recycling Co.',
      ),
      DriveSubmissionModel(
        submissionId: 'SUB_002',
        driveId: 'DRIVE_456',
        participantUid: 'user_marcus',
        participantName: 'Marcus Vance',
        participantEmail: 'marcus.v@example.com',
        participantPhone: '+1 (555) 432-1098',
        itemImageUrl: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=500',
        category: 'Small Appliances',
        notes: 'Defective espresso machine & microwave oven with copper magnetron.',
        weightKg: null,
        status: 'submitted', // Pending weight!
        submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      DriveSubmissionModel(
        submissionId: 'SUB_003',
        driveId: 'DRIVE_456',
        participantUid: 'user_sophia',
        participantName: 'Sophia Chen',
        participantEmail: 'sophia.c@example.com',
        participantPhone: '+1 (555) 789-0123',
        itemImageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
        category: 'Monitors & TVs',
        notes: 'Assorted server motherboard circuits and graphics cards.',
        weightKg: null,
        status: 'submitted', // Pending weight!
        submittedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      DriveSubmissionModel(
        submissionId: 'SUB_004',
        driveId: 'DRIVE_456',
        participantUid: 'user_arun',
        participantName: 'Arun Patel',
        participantEmail: 'arun.p@example.com',
        participantPhone: '+1 (555) 345-6789',
        itemImageUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500',
        category: 'Lithium Batteries',
        notes: 'UPS backup lead and lithium battery packs.',
        weightKg: 24.2,
        status: 'verified',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
        verifiedAt: DateTime.now().subtract(const Duration(hours: 8)),
        verifiedBy: 'Revive Tech Recycling Co.',
      ),
    ]);

    _emitDrives();
    _emitSubmissions();
  }

  void _emitDrives() {
    _drivesController.add(List.unmodifiable(_drives));
  }

  void _emitSubmissions() {
    _submissionsController.add(List.unmodifiable(_submissions));
  }

  // Getters
  List<DriveModel> get drives => List.unmodifiable(_drives);
  List<DriveSubmissionModel> get submissions => List.unmodifiable(_submissions);

  // Streams
  Stream<List<DriveModel>> streamDrives() async* {
    yield List.unmodifiable(_drives);
    yield* _drivesController.stream;
  }

  Stream<List<DriveSubmissionModel>> streamSubmissions() async* {
    yield List.unmodifiable(_submissions);
    yield* _submissionsController.stream;
  }

  Stream<List<DriveSubmissionModel>> streamSubmissionsForDrive(String driveId) async* {
    yield _submissions.where((s) => s.driveId == driveId).toList();
    yield* _submissionsController.stream.map(
      (list) => list.where((s) => s.driveId == driveId).toList(),
    );
  }

  Stream<List<DriveSubmissionModel>> streamUserSubmissions(String uid) async* {
    yield _submissions.where((s) => s.participantUid == uid).toList();
    yield* _submissionsController.stream.map(
      (list) => list.where((s) => s.participantUid == uid).toList(),
    );
  }

  // Actions
  Future<void> addSubmission(DriveSubmissionModel submission) async {
    _submissions.insert(0, submission);
    _emitSubmissions();
  }

  Future<void> updateVerifiedWeight({
    required String submissionId,
    required double weightKg,
    required String verifiedBy,
  }) async {
    final index = _submissions.indexWhere((s) => s.submissionId == submissionId);
    if (index != -1) {
      final old = _submissions[index];
      final updated = old.copyWith(
        weightKg: weightKg,
        status: 'verified',
        verifiedAt: DateTime.now(),
        verifiedBy: verifiedBy,
      );
      _submissions[index] = updated;

      // Update corresponding drive total weight
      final driveIdx = _drives.indexWhere((d) => d.driveId == old.driveId);
      if (driveIdx != -1) {
        final drive = _drives[driveIdx];
        final oldWeight = old.weightKg ?? 0.0;
        final newDriveWeight = drive.currentWeightKg - oldWeight + weightKg;
        _drives[driveIdx] = drive.copyWith(currentWeightKg: newDriveWeight);
        _emitDrives();
      }

      _emitSubmissions();
    }
  }

  UserModel? getUser(String uid) => _users[uid];

  void saveUser(UserModel user) {
    _users[user.uid] = user;
  }

  List<UserModel> getAllUsers() => _users.values.toList();
}
