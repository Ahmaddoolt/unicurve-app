class University {
  final int? id;
  final String name;
  final String shortName;
  final String uniType;
  final String uniLocation;

  University({
    this.id,
    required this.name,
    required this.shortName,
    required this.uniType,
    required this.uniLocation,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'short_name': shortName,
    'uni_type': uniType,
    'uni_location': uniLocation,
  };

  factory University.fromJson(Map<String, dynamic> json) => University(
    id: json['id'] as int?,
    name: json['name'] as String,
    shortName: json['short_name'] as String,
    uniType: json['uni_type'] as String,
    uniLocation: json['uni_location'] as String,
  );
}
