class Major {
  final int? id;
  final String name;
  final int universityId;

  Major({this.id, required this.name, required this.universityId});

  Map<String, dynamic> toJson() => {
    'name': name,
    'university_id': universityId,
  };

  factory Major.fromJson(Map<String, dynamic> json) => Major(
    id: json['id'] as int?,
    name: json['name'] as String,
    universityId: json['university_id'] as int,
  );
}
