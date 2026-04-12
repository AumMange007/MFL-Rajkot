class TutorModel {
  final String id;
  final String userId;
  final String instituteId;
  final String? tutorName;
  final String? tutorEmail;
  final String? tutorAvatarUrl;
  final String? mobile;
  final String? address;
  final String? bio;
  final String? experience;
  final String? specialization;

  final String? qualification;
  final String? dob;
 
  const TutorModel({
    required this.id,
    required this.userId,
    required this.instituteId,
    this.tutorName,
    this.tutorEmail,
    this.tutorAvatarUrl,
    this.mobile,
    this.address,
    this.bio,
    this.experience,
    this.specialization,
    this.qualification,
    this.dob,
  });
 
  factory TutorModel.fromJson(Map<String, dynamic> json) {
    // Check if nested users data is present (from joins)
    final userData = json['users'] as Map<String, dynamic>?;
    
    return TutorModel(
      id:             json['id'] as String,
      userId:         json['user_id'] as String,
      instituteId:    json['institute_id'] as String,
      tutorName:      userData?['name'] as String? ?? json['tutor_name'],
      tutorEmail:     userData?['email'] as String? ?? json['tutor_email'],
      tutorAvatarUrl:  userData?['avatar_url'] as String? ?? json['tutor_avatar_url'],
      mobile:         json['mobile'] as String?,
      address:        json['address'] as String?,
      bio:            json['bio'] as String?,
      experience:     json['experience'] as String?,
      specialization:  json['specialization'] as String?,
      qualification:   json['qualification'] as String?,
      dob:            json['dob'] as String?,
    );
  }
 
  Map<String, dynamic> toJson() => {
        'user_id':      userId,
        'institute_id': instituteId,
        'mobile':       mobile,
        'address':      address,
        'bio':          bio,
        'experience':   experience,
        'specialization': specialization,
        'qualification':  qualification,
        'dob':          dob,
      };
}
