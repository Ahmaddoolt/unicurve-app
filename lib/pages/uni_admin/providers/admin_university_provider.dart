import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_id_provider.dart';

// Provider for admin's university data
final adminUniversityProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Check cache
  final prefs = await SharedPreferences.getInstance();
  final cachedUniversityId = prefs.getInt('cached_university_id');
  final cachedUniversityName = prefs.getString('cached_university_name');
  final cacheTimestamp = prefs.getInt('cache_timestamp_university') ?? 0;
  final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
   const cacheDuration = 3600000; // 1 hour in milliseconds

  if (cachedUniversityId != null && cachedUniversityName != null && cacheAge < cacheDuration) {
    print('Loaded universityId: $cachedUniversityId from cache');
    return {
      'university_id': cachedUniversityId,
      'university_name': cachedUniversityName,
    };
  }

  // Fetch from Supabase
  try {
    final response = await Supabase.instance.client
        .from('uni_admin')
        .select('university_id, universities(name)')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      throw Exception('No university assigned to this admin');
    }

    final universityId = response['university_id'] as int?;
    final universityName = response['universities']?['name'] as String?;

    if (universityId == null) {
      throw Exception('No university ID found');
    }

    // Cache the data
    await prefs.setInt('cached_university_id', universityId);
    if (universityName != null) {
      await prefs.setString('cached_university_name', universityName);
    }
    await prefs.setInt('cache_timestamp_university', DateTime.now().millisecondsSinceEpoch);

    print('Fetched universityId: $universityId from Supabase');
    return {
      'university_id': universityId,
      'university_name': universityName ?? 'Unknown University',
    };
  } catch (e) {
    throw Exception('Failed to load university: $e');
  }
});
