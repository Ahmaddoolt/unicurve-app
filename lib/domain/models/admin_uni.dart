class Admin {
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String position;
  final int universityId;

  Admin({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.position,
    required this.universityId,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'email': email,
    'position': position,
    'university_id': universityId,
  };

  factory Admin.fromJson(Map<String, dynamic> json) => Admin(
    userId: json['user_id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    phoneNumber: json['phone_number'] as String,
    email: json['email'] as String,
    position: json['position'] as String,
    universityId: json['university_id'] as int,
  );
}
