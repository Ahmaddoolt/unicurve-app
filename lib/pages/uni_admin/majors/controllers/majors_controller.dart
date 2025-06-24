import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/domain/models/major.dart';

class MajorsController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchAdminUniversity(String? userId) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response =
          await _supabase
              .from('uni_admin')
              .select('university_id, universities(name)')
              .eq('user_id', userId)
              .single();

      final universityId = response['university_id'] as int?;
      if (universityId == null) {
        throw Exception('No university assigned to this admin');
      }

      return {
        'university_id': universityId,
        'university_name':
            response['universities']['name'] as String? ?? 'Unknown University',
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to load university: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Major>> fetchMajors(int universityId) async {
    try {
      final response = await _supabase
          .from('majors')
          .select('id, name, university_id')
          .eq('university_id', universityId)
          .order('name', ascending: true);

      final majors =
          (response as List<dynamic>)
              .map((json) => Major.fromJson(json))
              .where((major) => major.id != null)
              .toList();

      if (majors.isEmpty && response.isNotEmpty) {
        // print('Warning: Some majors were filtered out due to missing id');
      }

      await _cacheMajors(universityId, majors);
      return majors;
    } on PostgrestException catch (e) {
      throw Exception('Failed to load majors: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Major>?> getCachedMajors(int universityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_majors_$universityId');
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as List<dynamic>;
        final majors =
            decoded
                .map((json) => Major.fromJson(json))
                .where((major) => major.id != null)
                .toList();
        // print(
        //   'Loaded ${majors.length} majors from cache for universityId: $universityId',
        // );
        return majors.isNotEmpty ? majors : null;
      }
      // print('No cached majors found for universityId: $universityId');
      return null;
    } catch (e) {
      // print('Error loading cached majors: $e');
      return null;
    }
  }

  Future<void> _cacheMajors(int universityId, List<Major> majors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validMajors = majors.where((major) => major.id != null).toList();
      final jsonList = validMajors.map((major) => major.toJson()).toList();
      await prefs.setString(
        'cached_majors_$universityId',
        jsonEncode(jsonList),
      );
      // print(
      //   'Cached ${validMajors.length} majors for universityId: $universityId',
      // );
    } catch (e) {
      // print('Error caching majors: $e');
    }
  }

  Future<void> addMajor(Major major) async {
    try {
      final response =
          await _supabase
              .from('majors')
              .insert(major.toJson())
              .select('id, name, university_id')
              .single();

      final newMajor = Major.fromJson(response);
      if (newMajor.id == null) {
        throw Exception('Inserted major is missing id');
      }

      final cachedMajors = await getCachedMajors(major.universityId) ?? [];
      cachedMajors.add(newMajor);
      await _cacheMajors(major.universityId, cachedMajors);
    } on PostgrestException catch (e) {
      throw Exception('Failed to add major: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> updateMajor(int majorId, String name, int universityId) async {
    try {
      await _supabase
          .from('majors')
          .update({'name': name.trim()})
          .eq('id', majorId);

      final cachedMajors = await getCachedMajors(universityId) ?? [];
      final index = cachedMajors.indexWhere((m) => m.id == majorId);
      final updatedMajor = Major(
        id: majorId,
        name: name.trim(),
        universityId: universityId,
      );
      if (index != -1) {
        cachedMajors[index] = updatedMajor;
      } else {
        cachedMajors.add(updatedMajor);
      }
      await _cacheMajors(universityId, cachedMajors);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update major: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
