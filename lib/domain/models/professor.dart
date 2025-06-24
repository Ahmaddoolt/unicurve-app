class Professor {
  final int? id;
  final String? name;
  final int? majorId;

  Professor({this.id, this.name, this.majorId});

  Map<String, dynamic> toJson() => {'name': name, 'major_id': majorId};

  factory Professor.fromJson(Map<String, dynamic> json) => Professor(
    id: json['id'] as int?,
    name: json['name'] as String?,
    majorId: json['major_id'] as int?,
  );
}
