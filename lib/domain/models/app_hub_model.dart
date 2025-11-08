// lib/domain/models/app_hub_model.dart

class AppHubModel {
  final String id;
  final String name;
  final String? description;
  final String? type;
  final String? logoPath;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final double? rating;

  AppHubModel({
    required this.id,
    required this.name,
    this.description,
    this.type,
    this.logoPath,
    this.playStoreUrl,
    this.appStoreUrl,
    this.rating,
  });

  factory AppHubModel.fromJson(Map<String, dynamic> json) {
    return AppHubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String?,
      logoPath: json['logo_path'] as String?,
      playStoreUrl: json['play_store_url'] as String?,
      appStoreUrl: json['app_store_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}