class LeadModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? interestedIn; // course/batch interested in
  final String? source; // how they heard about us
  final String? notes;
  final String status; // 'new', 'contacted', 'potential', 'enrolled', 'dropped'
  final DateTime createdAt;
  final DateTime? followUpDate;

  const LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.interestedIn,
    this.source,
    this.notes,
    required this.status,
    required this.createdAt,
    this.followUpDate,
  });

  factory LeadModel.fromMap(Map<String, dynamic> map) {
    return LeadModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      interestedIn: map['interested_in'] as String?,
      source: map['source'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'new',
      createdAt: DateTime.parse(map['created_at'] as String),
      followUpDate: map['follow_up_date'] != null
          ? DateTime.parse(map['follow_up_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'interested_in': interestedIn,
        'source': source,
        'notes': notes,
        'status': status,
        'follow_up_date': followUpDate?.toIso8601String().split('T').first,
      };

  LeadModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? interestedIn,
    String? source,
    String? notes,
    String? status,
    DateTime? followUpDate,
  }) =>
      LeadModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        interestedIn: interestedIn ?? this.interestedIn,
        source: source ?? this.source,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt,
        followUpDate: followUpDate ?? this.followUpDate,
      );
}
