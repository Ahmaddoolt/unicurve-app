// lib/data/services/app_hub_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/domain/models/app_hub_model.dart';
import 'package:unicurve/main.dart'; // To access our second Supabase client

class AppHubService {
  final SupabaseClient _client;

  AppHubService(this._client);

  Future<List<AppHubModel>> getAllApps() async {
    try {
      final response = await _client
          .from('all_apps')
          .select()
          .eq('is_active', true) // Only fetch active apps
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      
      return response.map((json) => AppHubModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching apps from App Hub: $e');
      throw Exception('Failed to load our apps.');
    }
  }
}

// Provider for the service itself
final appHubServiceProvider = Provider<AppHubService>((ref) {
  final client = ref.watch(appHubSupabaseClientProvider);
  return AppHubService(client);
});

// The main provider our UI will watch to get the list of apps
final allAppsProvider = FutureProvider<List<AppHubModel>>((ref) {
  final service = ref.watch(appHubServiceProvider);
  return service.getAllApps();
});