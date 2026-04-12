class AttendanceModel {
  final String id;
  final String studentId;
  final String batchId;
  final DateTime date;
  final String status; // 'present' | 'absent' | 'late'
  final String instituteId;
  final String? markedBy;

  // Joined fields
  final String? studentName;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.batchId,
    required this.date,
    required this.status,
    required this.instituteId,
    this.markedBy,
    this.studentName,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      AttendanceModel(
        id:          json['id'] as String,
        studentId:   json['student_id'] as String,
        batchId:     json['batch_id'] as String,
        date:        DateTime.parse(json['date'] as String),
        status:      json['status'] as String,
        instituteId: json['institute_id'] as String,
        markedBy:    json['marked_by'] as String?,
        studentName: json['students'] != null && (json['students'] as Map<String, dynamic>)['users'] != null
            ? (json['students'] as Map<String, dynamic>)['users']['name'] as String?
            : null,
      );

  Map<String, dynamic> toJson() => {
        'student_id':   studentId,
        'batch_id':     batchId,
        'date':         date.toIso8601String().split('T').first,
        'status':       status,
        'institute_id': instituteId,
        'marked_by':    markedBy,
      };

  bool get isPresent => status == 'present';
  bool get isAbsent  => status == 'absent';
  bool get isLate    => status == 'late';
}
