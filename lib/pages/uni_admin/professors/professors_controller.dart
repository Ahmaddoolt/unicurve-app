import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/professors/professors_supabase_service.dart';
import 'package:unicurve/pages/uni_admin/providers/professors_provider.dart';

class ProfessorsController extends StateNotifier<List<Professor>> {
  final SupabaseService supabaseService = SupabaseService();
  final int? majorId;
  final TextEditingController searchController = TextEditingController();
  String? majorName;
  bool isLoading = false;

  ProfessorsController(this.majorId) : super([]) {
    searchController.addListener(() => state = state); // Trigger rebuild without modifying state
  }

  Future<void> initialize() async {
    await fetchProfessorsAndMajor();
  }

  Future<void> fetchProfessorsAndMajor() async {
    isLoading = true;
    state = []; // Reset state
    try {
      majorName = await supabaseService.fetchMajorName(majorId);
      final professors = await supabaseService.fetchProfessors(majorId);
      state = professors;
    } catch (e) {
      showSnackBar('Error fetching data: $e', isError: true);
    } finally {
      isLoading = false;
    }
  }

  Future<void> addProfessor({
    required String name,
    required Map<int, bool> subjectSelection,
    required Map<int, bool> subjectActiveStatus,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    isLoading = true;
    try {
      final newProfessor = Professor(name: name, majorId: majorId);
      final insertedProfessor = await supabaseService.insertProfessor(newProfessor);
      final subjectInserts = subjectSelection.entries
          .where((entry) => entry.value)
          .map((entry) => {
                'professor_id': insertedProfessor.id,
                'subject_id': entry.key,
                'isActive': subjectActiveStatus[entry.key] ?? false,
              })
          .toList();
      await supabaseService.insertSubjectProfessors(subjectInserts);
      state = [...state, insertedProfessor];

      // Invalidate cache and refresh provider
      ref.invalidate(professorsProvider(majorId!));
      showSnackBar('Professor and subjects added successfully', context: context);
    } catch (e) {
      showSnackBar('Error adding professor: $e', isError: true, context: context);
    } finally {
      isLoading = false;
    }
  }

  Future<void> editProfessor({
    required Professor professor,
    required String name,
    required Map<int, bool> subjectSelection,
    required Map<int, bool> subjectActiveStatus,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    isLoading = true;
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
          .map((entry) => {
                'professor_id': professor.id,
                'subject_id': entry.key,
                'isActive': subjectActiveStatus[entry.key] ?? false,
              })
          .toList();
      await supabaseService.insertSubjectProfessors(subjectInserts);
      state = state.map((p) => p.id == professor.id ? updatedProfessor : p).toList();

      // Invalidate cache and refresh provider
      ref.invalidate(professorsProvider(majorId!));
      showSnackBar('Professor and subjects updated successfully', context: context);
    } catch (e) {
      showSnackBar('Error updating professor: $e', isError: true, context: context);
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteProfessor(int? professorId, BuildContext context, [WidgetRef? ref]) async {
    final scaleConfig = ScaleConfig(context);
    bool confirmDelete = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        title: Text(
          'Delete Professor',
          style: TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(18),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this professor? This will also remove all their teaching assignments.',
          style: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: scaleConfig.scaleText(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: scaleConfig.scaleText(14),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              confirmDelete = true;
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontSize: scaleConfig.scaleText(14),
              ),
            ),
          ),
        ],
      ),
    );

    if (!confirmDelete) return;

    isLoading = true;
    try {
      await supabaseService.deleteSubjectProfessors(professorId);
      await supabaseService.deleteProfessor(professorId);
      state = state.where((p) => p.id != professorId).toList();

      // Invalidate cache and refresh provider
      if (ref != null) {
        ref.invalidate(professorsProvider(majorId!));
      }
      showSnackBar('Professor and all related subject assignments deleted successfully', context: context);
    } catch (e) {
      showSnackBar('Error deleting professor: $e', isError: true, context: context);
    } finally {
      isLoading = false;
    }
  }

  Future<Map<String, dynamic>> fetchProfessorDetails(Professor professor) async {
    isLoading = true;
    try {
      final assignedSubjectIds = await supabaseService.fetchTeachingAssignments(professor.id);
      final canTeachSubjects = await supabaseService.fetchSubjects(professor.majorId);
      final filteredCanTeachSubjects = canTeachSubjects
          .where((subject) => assignedSubjectIds.containsKey(subject.id ?? 0))
          .toList();
      final teachingSubjects = await supabaseService.fetchTeachingSubjects(professor.id);
      return {
        'canTeachSubjects': filteredCanTeachSubjects,
        'teachingSubjects': teachingSubjects,
      };
    } catch (e) {
      showSnackBar('Error fetching professor details: $e', isError: true);
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<List<Subject>> fetchAvailableSubjects() async {
    return await supabaseService.fetchSubjects(majorId);
  }

  Future<Map<int, bool>> fetchSubjectAssignments(int? professorId) async {
    return await supabaseService.fetchTeachingAssignments(professorId);
  }

  void showSnackBar(String message, {bool isError = false, BuildContext? context}) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: ScaleConfig(context).scaleText(14),
            ),
          ),
          backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScaleConfig(context).scale(8)),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

final professorsControllerProvider = StateNotifierProvider.family<ProfessorsController, List<Professor>, int?>((ref, majorId) {
  return ProfessorsController(majorId);
});