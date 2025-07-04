class Student {
  final String? userId;
  final String firstName;
  final String lastName;
  final String uniNumber;
  final int universityId;
  final int majorId;
  final String email;
  final String? password;

  Student({
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.uniNumber,
    required this.universityId,
    required this.majorId,
    required this.email,
    this.password,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'first_name': firstName,
    'last_name': lastName,
    'uni_number': uniNumber,
    'university_id': universityId,
    'major_id': majorId,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    userId: json['user_id'] as String?,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    uniNumber: json['uni_number'] as String,
    universityId: json['university_id'] as int,
    majorId: json['major_id'] as int,
    email: json['email'] as String,
  );
}
