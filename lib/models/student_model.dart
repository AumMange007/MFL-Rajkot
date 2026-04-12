class StudentModel {
  final String id;
  final String userId;
  final String batchId;
  final String instituteId;
  final DateTime? enrolledAt;

  // Language & Progress
  final String? language;
  final String? level;
  
  // Specific Chapters
  final String vocabChap;
  final String grammarChap;
  final String kbChap; 
  final String ubChap;

  // Student Profile Data
  final String? mobile;
  final String? parentMobile;
  final String? address;
  final String? dateOfBirth;
  final DateTime? progressUpdatedAt;

  // Joined fields
  final String? studentName;
  final String? studentEmail;
  final String? studentUsername;
  final String? studentAvatarUrl; // New
  final String? batchName;
  final String? tutorName; 

  const StudentModel({
    required this.id,
    required this.userId,
    required this.batchId,
    required this.instituteId,
    this.enrolledAt,
    this.language = 'German',
    this.level = 'A1',
    this.vocabChap = '1',
    this.grammarChap = '1',
    this.kbChap = '1',
    this.ubChap = '1',
    this.mobile,
    this.parentMobile,
    this.address,
    this.dateOfBirth,
    this.progressUpdatedAt,
    this.studentName,
    this.studentEmail,
    this.studentUsername,
    this.studentAvatarUrl,
    this.batchName,
    this.tutorName,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id:          json['id'] as String,
        userId:      json['user_id'] as String,
        batchId:     json['batch_id'] as String,
        instituteId: json['institute_id'] as String,
        enrolledAt:  json['enrolled_at'] != null
            ? DateTime.parse(json['enrolled_at'] as String)
            : null,
        language:    json['language']?.toString() ?? 'German',
        level:       json['level']?.toString() ?? 'A1',
        vocabChap:   json['vocab_chap']?.toString() ?? '1',
        grammarChap: json['grammar_chap']?.toString() ?? '1',
        kbChap:      json['kb_chap']?.toString() ?? '1',
        ubChap:      json['ub_chap']?.toString() ?? '1',
        mobile:      json['mobile']?.toString(),
        parentMobile: json['parent_mobile']?.toString(),
        address:     json['address']?.toString(),
        dateOfBirth:  json['dob']?.toString(),
        // Joined from users table
        studentName: json['users'] is Map
            ? (json['users'] as Map<String, dynamic>)['name']?.toString()
            : null,
        studentEmail: json['users'] is Map
            ? (json['users'] as Map<String, dynamic>)['email']?.toString()
            : null,
        studentUsername: json['users'] is Map
            ? (json['users'] as Map<String, dynamic>)['username']?.toString()
            : null,
        studentAvatarUrl: json['users'] is Map
            ? (json['users'] as Map<String, dynamic>)['avatar_url']?.toString()
            : null,
        // Joined from batches table
        batchName: json['batches'] is Map
            ? (json['batches'] as Map<String, dynamic>)['name']?.toString()
            : null,
        // Joined from tutor (via batch)
        tutorName: json['tutors'] is Map
            ? (json['tutors'] as Map<String, dynamic>)['name']?.toString()
            : null,
        progressUpdatedAt: json['progress_updated_at'] != null
            ? DateTime.parse(json['progress_updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'user_id':      userId,
        'batch_id':     batchId,
        'institute_id': instituteId,
        'language':     language,
        'level':        level,
        'vocab_chap':   vocabChap,
        'grammar_chap': grammarChap,
        'kb_chap':      kbChap,
        'ub_chap':      ubChap,
        'mobile':       mobile,
        'parent_mobile': parentMobile,
        'address':      address,
        'dob':          dateOfBirth,
      };
}
