class DriveSubmissionModel {
  final String submissionId;
  final String driveId;
  final String participantUid;
  final String participantName;
  final String participantEmail;
  final String participantPhone;
  final String itemImageUrl;
  final String category;
  final String notes;
  final double? weightKg;
  final String status; // 'submitted' | 'verified'
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  DriveSubmissionModel({
    required this.submissionId,
    required this.driveId,
    required this.participantUid,
    required this.participantName,
    required this.participantEmail,
    required this.participantPhone,
    required this.itemImageUrl,
    this.category = 'General Electronics',
    this.notes = '',
    this.weightKg,
    required this.status,
    DateTime? submittedAt,
    this.verifiedAt,
    this.verifiedBy,
  }) : submittedAt = submittedAt ?? DateTime.now();

  bool get isVerified => status == 'verified' && weightKg != null;

  factory DriveSubmissionModel.fromMap(String id, Map<String, dynamic> data) {
    return DriveSubmissionModel(
      submissionId: id,
      driveId: data['driveId'] as String? ?? '',
      participantUid: data['participantUid'] as String? ?? '',
      participantName: data['participantName'] as String? ?? 'Anonymous',
      participantEmail: data['participantEmail'] as String? ?? '',
      participantPhone: data['participantPhone'] as String? ?? '',
      itemImageUrl: data['itemImageUrl'] as String? ?? '',
      category: data['category'] as String? ?? 'General Electronics',
      notes: data['notes'] as String? ?? '',
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      status: data['status'] as String? ?? 'submitted',
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] is DateTime
              ? data['submittedAt'] as DateTime
              : DateTime.tryParse(data['submittedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] is DateTime
              ? data['verifiedAt'] as DateTime
              : DateTime.tryParse(data['verifiedAt'].toString()))
          : null,
      verifiedBy: data['verifiedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'driveId': driveId,
      'participantUid': participantUid,
      'participantName': participantName,
      'participantEmail': participantEmail,
      'participantPhone': participantPhone,
      'itemImageUrl': itemImageUrl,
      'category': category,
      'notes': notes,
      'weightKg': weightKg,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  DriveSubmissionModel copyWith({
    String? submissionId,
    String? driveId,
    String? participantUid,
    String? participantName,
    String? participantEmail,
    String? participantPhone,
    String? itemImageUrl,
    String? category,
    String? notes,
    double? weightKg,
    String? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return DriveSubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      driveId: driveId ?? this.driveId,
      participantUid: participantUid ?? this.participantUid,
      participantName: participantName ?? this.participantName,
      participantEmail: participantEmail ?? this.participantEmail,
      participantPhone: participantPhone ?? this.participantPhone,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      weightKg: weightKg ?? this.weightKg,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}
