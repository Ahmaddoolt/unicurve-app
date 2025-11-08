// lib/pages/uni_admin/providers/professors_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/pages/uni_admin/professors/professors_supabase_service.dart';

final professorsProvider = StateNotifierProvider.autoDispose
    .family<ProfessorsNotifier, AsyncValue<List<Professor>>, int>((
  ref,
  majorId,
) {
  final notifier = ProfessorsNotifier(majorId);
  ref.keepAlive();
  return notifier;
});

class ProfessorsNotifier extends StateNotifier<AsyncValue<List<Professor>>> {
  final int majorId;
  // --- FIX: Made the service public by removing the underscore ---
  final SupabaseService supabaseService = SupabaseService();
  final TextEditingController searchController = TextEditingController();

  List<Professor> _fullProfessorList = [];

  ProfessorsNotifier(this.majorId) : super(const AsyncValue.loading()) {
    searchController.addListener(_filterProfessors);
    fetchProfessors();
  }

  Future<void> fetchProfessors() async {
    state = const AsyncValue.loading();
    try {
      final professors = await supabaseService.fetchProfessors(majorId);
      _fullProfessorList = professors;
      _filterProfessors();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _filterProfessors() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      state = AsyncValue.data(_fullProfessorList);
    } else {
      final filteredList = _fullProfessorList
          .where((p) => (p.name?.toLowerCase() ?? '').contains(query))
          .toList();
      state = AsyncValue.data(filteredList);
    }
  }

  Future<void> addProfessor({
    required String name,
    required Map<int, bool> subjectSelection,
    required Map<int, bool> subjectActiveStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newProfessor = Professor(name: name, majorId: majorId);
      final insertedProfessor = await supabaseService.insertProfessor(
        newProfessor,
      );

      final subjectInserts = subjectSelection.entries
          .where((entry) => entry.value)
          .map(
            (entry) => {
              'professor_id': insertedProfessor.id,
              'subject_id': entry.key,
              'isActive': subjectActiveStatus[entry.key] ?? false,
            },
          )
          .toList();
      if (subjectInserts.isNotEmpty) {
        await supabaseService.insertSubjectProfessors(subjectInserts);
      }
      await fetchProfessors();
    } catch (e) {
      await fetchProfessors();
      rethrow;
    }
  }

  Future<void> editProfessor({
    required Professor professor,
    required String name,
    required Map<int, bool> subjectSelection,
    required Map<int, bool> subjectActiveStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedProfessor = Professor(
        id: professor.id,
        name: name,
        majorId: majorId,
      );
      await supabaseService.updateProfessor(updatedProfessor);
      await supabaseService.deleteSubjectProfessors(professor.id);

      final subjectInserts = subjectSelection.entries
          .where((entry) => entry.value)
          .map(
            (entry) => {
              'professor_id': professor.id,
              'subject_id': entry.key,
              'isActive': subjectActiveStatus[entry.key] ?? false,
            },
          )
          .toList();
      if (subjectInserts.isNotEmpty) {
        await supabaseService.insertSubjectProfessors(subjectInserts);
      }
      await fetchProfessors();
    } catch (e) {
      await fetchProfessors();
      rethrow;
    }
  }

  Future<void> deleteProfessor(int? professorId) async {
    if (professorId == null) return;

    final previousList = _fullProfessorList;
    _fullProfessorList =
        _fullProfessorList.where((p) => p.id != professorId).toList();
    _filterProfessors();

    try {
      await supabaseService.deleteSubjectProfessors(professorId);
      await supabaseService.deleteProfessor(professorId);
    } catch (e) {
      _fullProfessorList = previousList;
      _filterProfessors();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchProfessorDetails(
    Professor professor,
  ) async {
    try {
      final canTeachSubjects = await supabaseService.fetchSubjectsForProfessor(
        professor.id,
      );
      final teachingSubjects = await supabaseService.fetchTeachingSubjects(
        professor.id,
      );
      return {
        'canTeachSubjects': canTeachSubjects,
        'teachingSubjects': teachingSubjects,
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_filterProfessors);
    searchController.dispose();
    super.dispose();
  }
}
