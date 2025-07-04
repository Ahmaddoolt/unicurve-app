class UniAdmin {
  final int? id;
  final String? userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String? password;
  final String position;
  final String universityName;
  final String universityShortName;
  final String universityType;
  final String universityLocation;
  final bool isApproved;

  UniAdmin({
    this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    this.password,
    required this.position,
    required this.universityName,
    required this.universityShortName,
    required this.universityType,
    required this.universityLocation,
    this.isApproved = false,
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'email': email,
    'position': position,
    'university_name': universityName,
    'university_name_short': universityShortName,
    'university_type': universityType,
    'university_location': universityLocation,
    'is_approved': isApproved,
  };

  factory UniAdmin.fromJson(Map<String, dynamic> json) => UniAdmin(
    id: json['id'] as int?,
    userId: json['user_id'] as String?,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    phoneNumber: json['phone_number'] as String,
    email: json['email'] as String,
    position: json['position'] as String,
    universityName: json['university_name'] as String,
    universityShortName: json['university_name_short'] as String,
    universityType: json['university_type'] as String,
    universityLocation: json['university_location'] as String,
    isApproved: json['is_approved'] as bool,
  );
}
