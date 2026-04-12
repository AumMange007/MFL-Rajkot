class AnnouncementModel {
  final String id;
  final String title;
  final String message; // Matches SQL 'message'
  final String instituteId;
  final String? createdBy; // Matches SQL 'created_by'
  final String creatorName;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.instituteId,
    this.createdBy,
    required this.creatorName,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      instituteId: json['institute_id'] as String,
      createdBy: json['created_by'] as String?,
      creatorName: json['users'] != null ? json['users']['name'] : 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
