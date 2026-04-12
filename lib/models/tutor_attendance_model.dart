class StaffAttendanceModel {
  final String id;
  final String userId;
  final String instituteId;
  final DateTime punchInAt;
  final DateTime? punchOutAt;
  final String date;
  final bool isOnPremise;
  final double? lat;
  final double? lng;

  StaffAttendanceModel({
    required this.id,
    required this.userId,
    required this.instituteId,
    required this.punchInAt,
    this.punchOutAt,
    required this.date,
    this.isOnPremise = false,
    this.lat,
    this.lng,
  });

  factory StaffAttendanceModel.fromJson(Map<String, dynamic> json) => StaffAttendanceModel(
    id:            json['id'] as String,
    userId:        json['user_id'] as String,
    instituteId:   json['institute_id'] as String,
    punchInAt:     DateTime.parse(json['punch_in_at'] as String),
    punchOutAt:    json['punch_out_at'] != null ? DateTime.parse(json['punch_out_at'] as String) : null,
    date:          json['date'] as String,
    isOnPremise:   json['is_on_premise'] == true,
    lat:           json['location_lat']?.toDouble(),
    lng:           json['location_lng']?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'user_id':      userId,
    'institute_id': instituteId,
    'punch_in_at':  punchInAt.toIso8601String(),
    'punch_out_at': punchOutAt?.toIso8601String(),
    'date':         date,
    'is_on_premise': isOnPremise,
    'location_lat': lat,
    'location_lng': lng,
  };
}
