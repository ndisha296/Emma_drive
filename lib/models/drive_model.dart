class DriveModel {
  final String driveId;
  final String title;
  final String description;
  final String manufacturerId;
  final String manufacturerName;
  final String location;
  final DateTime date;
  final List<String> acceptedCategories;
  final double targetWeightKg;
  final double currentWeightKg;
  final String status; // 'upcoming', 'active', 'completed'

  DriveModel({
    required this.driveId,
    required this.title,
    required this.description,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.location,
    required this.date,
    required this.acceptedCategories,
    this.targetWeightKg = 500.0,
    this.currentWeightKg = 0.0,
    this.status = 'active',
  });

  factory DriveModel.fromMap(String id, Map<String, dynamic> data) {
    return DriveModel(
      driveId: id,
      title: data['title'] as String? ?? 'Community Waste Drive',
      description: data['description'] as String? ?? 'Recycling collection drive',
      manufacturerId: data['manufacturerId'] as String? ?? '',
      manufacturerName: data['manufacturerName'] as String? ?? 'Eco Manufacturer',
      location: data['location'] as String? ?? 'Community Center',
      date: data['date'] != null
          ? (data['date'] is DateTime
              ? data['date'] as DateTime
              : DateTime.tryParse(data['date'].toString()) ?? DateTime.now())
          : DateTime.now().add(const Duration(days: 3)),
      acceptedCategories: (data['acceptedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Laptops & PCs', 'Smartphones', 'Batteries', 'Household Electronics'],
      targetWeightKg: (data['targetWeightKg'] as num?)?.toDouble() ?? 500.0,
      currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driveId': driveId,
      'title': title,
      'description': description,
      'manufacturerId': manufacturerId,
      'manufacturerName': manufacturerName,
      'location': location,
      'date': date.toIso8601String(),
      'acceptedCategories': acceptedCategories,
      'targetWeightKg': targetWeightKg,
      'currentWeightKg': currentWeightKg,
      'status': status,
    };
  }

  DriveModel copyWith({
    String? driveId,
    String? title,
    String? description,
    String? manufacturerId,
    String? manufacturerName,
    String? location,
    DateTime? date,
    List<String>? acceptedCategories,
    double? targetWeightKg,
    double? currentWeightKg,
    String? status,
  }) {
    return DriveModel(
      driveId: driveId ?? this.driveId,
      title: title ?? this.title,
      description: description ?? this.description,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      location: location ?? this.location,
      date: date ?? this.date,
      acceptedCategories: acceptedCategories ?? this.acceptedCategories,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      status: status ?? this.status,
    );
  }
}
