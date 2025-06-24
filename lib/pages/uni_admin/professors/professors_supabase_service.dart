import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/domain/models/major.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/domain/models/subject.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Major> fetchSingleMajor(int majorId) async {
    final response =
        await _client
            .from('majors')
            .select('id, name, university_id')
            .eq('id', majorId)
            .single();
    return Major.fromJson(response);
  }

  Future<String?> fetchMajorName(int? majorId) async {
    if (majorId == null) return null;
    final response =
        await _client.from('majors').select('name').eq('id', majorId).single();
    return response['name'] as String?;
  }

  Future<List<Professor>> fetchProfessors(int? majorId) async {
    if (majorId == null) return [];
    final response = await _client
        .from('professors')
        .select('id, name, major_id')
        .eq('major_id', majorId)
        .order('name', ascending: true);
    return (response as List<dynamic>)
        .map((json) => Professor.fromJson(json))
        .toList();
  }

  Future<List<Subject>> fetchSubjects(int? majorId) async {
    if (majorId == null) return [];
    final response = await _client
        .from('subjects')
        .select(
          'id, code, name, description, hours, is_open, major_id, level, priority, type',
        )
        .eq('major_id', majorId);
    return (response as List<dynamic>)
        .map((json) => Subject.fromMap(json))
        .toList();
  }

  Future<Map<int, bool>> fetchTeachingAssignments(int? professorId) async {
    if (professorId == null) return {};
    final response = await _client
        .from('subject_professors')
        .select('subject_id, isActive')
        .eq('professor_id', professorId);
    return {
      for (var item in response as List<dynamic>)
        item['subject_id'] as int: item['isActive'] as bool,
    };
  }

  Future<List<Subject>> fetchSubjectsForProfessor(int? professorId) async {
    if (professorId == null) return [];
    final response = await _client
        .from('subject_professors')
        .select(
          'subjects!inner(id, code, name, description, hours, is_open, major_id, level, priority, type)',
        )
        .eq('professor_id', professorId);

    return (response as List<dynamic>)
        .map((t) => Subject.fromMap(t['subjects']))
        .toList();
  }

  Future<List<Subject>> fetchTeachingSubjects(int? professorId) async {
    if (professorId == null) return [];
    final response = await _client
        .from('subject_professors')
        .select(
          'subject_id, isActive, subjects!subject_professors_subject_id_fkey(id, code, name, description, hours, is_open, major_id, level, priority, type)',
        )
        .eq('professor_id', professorId)
        .eq('isActive', true);
    return (response as List<dynamic>)
        .where((t) => t['subjects']['is_open'] == true)
        .map((t) => Subject.fromMap(t['subjects']))
        .toList();
  }

  Future<Professor> insertProfessor(Professor professor) async {
    final response =
        await _client
            .from('professors')
            .insert(professor.toJson())
            .select('id, name, major_id')
            .single();
    return Professor.fromJson(response);
  }

  Future<void> insertSubjectProfessors(
    List<Map<String, dynamic>> subjectInserts,
  ) async {
    if (subjectInserts.isNotEmpty) {
      await _client.from('subject_professors').insert(subjectInserts);
    }
  }

  Future<void> updateProfessor(Professor professor) async {
    if (professor.id == null) throw Exception('Professor ID is null');
    await _client
        .from('professors')
        .update(professor.toJson())
        .eq('id', professor.id!);
  }

  Future<void> deleteSubjectProfessors(int? professorId) async {
    if (professorId == null) return;
    await _client
        .from('subject_professors')
        .delete()
        .eq('professor_id', professorId);
  }

  Future<void> deleteProfessor(int? professorId) async {
    if (professorId == null) return;
    await _client.from('professors').delete().eq('id', professorId);
  }
}
