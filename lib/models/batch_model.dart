
class BatchModel {
  final String id;
  final String name;
  final String instituteId;
  final DateTime? createdAt;

  // Multiple Tutors support
  final List<String> tutorIds;
  final List<String> tutorNames;

  const BatchModel({
    required this.id,
    required this.name,
    required this.instituteId,
    this.createdAt,
    this.tutorIds = const [],
    this.tutorNames = const [],
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    // When querying with join: .select('*, batch_tutors(*, users:tutor_id(name))')
    final tutorsData = json['batch_tutors'] as List?;
    final ids = <String>[];
    final names = <String>[];

    if (tutorsData != null) {
      for (var t in tutorsData) {
        final tid = t['tutor_id'] as String?;
        if (tid != null) ids.add(tid);
        
        final u = t['users'] as Map<String, dynamic>?;
        if (u != null && u['name'] != null) {
          names.add(u['name'] as String);
        }
      }
    }

    return BatchModel(
      id:          json['id'] as String,
      name:        json['name'] as String,
      instituteId: json['institute_id'] as String,
      createdAt:   json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      tutorIds:    ids,
      tutorNames:  names,
    );
  }

  Map<String, dynamic> toJson() => {
        'name':         name,
        'institute_id': instituteId,
      };
}
