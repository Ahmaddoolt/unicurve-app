import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/pages/uni_admin/professors/professors_supabase_service.dart';

final majorsProvider = FutureProvider.family<List<Major>, int>((
  ref,
  universityId,
) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString('cached_majors_$universityId');
  final cacheTimestamp =
      prefs.getInt('cache_timestamp_majors_$universityId') ?? 0;
  final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
  const cacheDuration = 3600000;

  if (cachedData != null && cacheAge < cacheDuration) {
    final decoded = jsonDecode(cachedData) as List<dynamic>;
    final majors =
        decoded
            .map((json) => Major.fromJson(json))
            .where((major) => major.id != null)
            .toList();
    if (majors.isNotEmpty) {
      // print(
      //   'Loaded ${majors.length} majors from cache for universityId: $universityId',
      // );
      return majors;
    }
  }

  try {
    final response = await Supabase.instance.client
        .from('majors')
        .select('id, name, university_id')
        .eq('university_id', universityId)
        .order('name', ascending: true);

    final majors =
        (response as List<dynamic>)
            .map((json) => Major.fromJson(json))
            .where((major) => major.id != null)
            .toList();

    final validMajors = majors.where((major) => major.id != null).toList();
    final jsonList = validMajors.map((major) => major.toJson()).toList();
    await prefs.setString('cached_majors_$universityId', jsonEncode(jsonList));
    await prefs.setInt(
      'cache_timestamp_majors_$universityId',
      DateTime.now().millisecondsSinceEpoch,
    );
    // print(
    //   'Fetched ${majors.length} majors from Supabase for universityId: $universityId',
    // );

    return majors;
  } catch (e) {
    throw Exception('Failed to load majors: $e');
  }
});

class MajorsNotifier extends StateNotifier<List<Major>> {
  MajorsNotifier() : super([]);

  Future<void> addMajor(Major major, WidgetRef ref) async {
    try {
      final response =
          await Supabase.instance.client
              .from('majors')
              .insert(major.toJson())
              .select('id, name, university_id')
              .single();

      final newMajor = Major.fromJson(response);
      if (newMajor.id == null) {
        throw Exception('Inserted major is missing id');
      }

      final universityId = major.universityId;
      final cachedMajors = await ref.read(majorsProvider(universityId).future);
      final updatedMajors = [...cachedMajors, newMajor];
      state = updatedMajors;

      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedMajors.map((m) => m.toJson()).toList();
      await prefs.setString(
        'cached_majors_$universityId',
        jsonEncode(jsonList),
      );
      await prefs.setInt(
        'cache_timestamp_majors_$universityId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw Exception('Failed to add major: $e');
    }
  }

  Future<void> updateMajor(
    int majorId,
    String name,
    int universityId,
    WidgetRef ref,
  ) async {
    try {
      await Supabase.instance.client
          .from('majors')
          .update({'name': name.trim()})
          .eq('id', majorId);

      final cachedMajors = await ref.read(majorsProvider(universityId).future);
      final updatedMajors =
          cachedMajors.map((m) {
            if (m.id == majorId) {
              return Major(
                id: m.id,
                name: name.trim(),
                universityId: m.universityId,
              );
            }
            return m;
          }).toList();
      state = updatedMajors;

      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedMajors.map((m) => m.toJson()).toList();
      await prefs.setString(
        'cached_majors_$universityId',
        jsonEncode(jsonList),
      );
      await prefs.setInt(
        'cache_timestamp_majors_$universityId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw Exception('Failed to update major: $e');
    }
  }
}

final majorsNotifierProvider =
    StateNotifierProvider<MajorsNotifier, List<Major>>((ref) {
      return MajorsNotifier();
    });

final majorDetailsProvider = FutureProvider.autoDispose.family<Major, int>((
  ref,
  majorId,
) async {
  final supabaseService = SupabaseService();
  return supabaseService.fetchSingleMajor(majorId);
});
