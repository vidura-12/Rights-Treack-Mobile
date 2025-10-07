class UserProfile {
  final String? country;
  final DateTime? createdAt;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? state;

  UserProfile({
    this.country,
    this.createdAt,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.state,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      country: data['country'],
      createdAt: data['createdAt']?.toDate(),
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'],
      state: data['state'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (country != null) 'country': country,
      if (createdAt != null) 'createdAt': createdAt,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (state != null) 'state': state,
    };
  }

  UserProfile copyWith({
    String? country,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? state,
  }) {
    return UserProfile(
      country: country ?? this.country,
      createdAt: createdAt,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      state: state ?? this.state,
    );
  }
}