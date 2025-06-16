// lib/pages/student/term_gpa_calculator_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/providers/academic_profile_provider.dart';

class SubjectEntry {
  final int id;
  final String name;
  final int hours;
  int mark;
  final TextEditingController markController;

  SubjectEntry({required this.id, required this.name, required this.hours, this.mark = 85})
      : markController = TextEditingController(text: mark.toString());

  void dispose() {
    markController.dispose();
  }
}

class TermGpaCalculatorPage extends ConsumerStatefulWidget {
  const TermGpaCalculatorPage({super.key});

  @override
  ConsumerState<TermGpaCalculatorPage> createState() => _TermGpaCalculatorPageState();
}

class _TermGpaCalculatorPageState extends ConsumerState<TermGpaCalculatorPage> {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _allSubjects = [];
  final List<SubjectEntry> _selectedSubjects = [];
  
  double _termGpa = 0.0;
  int _termHours = 0;
  
  double _projectedGpa = 0.0;
  double _historicalQualityPoints = 0.0;
  int _historicalHours = 0;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeData());
  }
  
  void _initializeData() {
    final profileAsync = ref.read(academicProfileProvider);
    profileAsync.when(
      data: (profile) {
        setState(() {
          _historicalQualityPoints = profile.totalHistoricalQualityPoints;
          _historicalHours = profile.totalHistoricalHours;
        });
        _calculateProjectedGpa();
        _fetchSubjectsForMajor(profile.takenSubjects);
      },
      loading: () => setState(() => _isLoading = true),
      error: (e, st) => setState(() {
        _isLoading = false;
        _errorMessage = "Could not load profile data: $e";
      }),
    );
  }
  
  @override
  void dispose() {
    for (var entry in _selectedSubjects) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSubjectsForMajor(List<Map<String, dynamic>> takenSubjects) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in.");

      final studentResponse = await supabase.from('students').select('major_id').eq('user_id', userId).single();
      final majorId = studentResponse['major_id'];
      if (majorId == null) throw Exception("You are not enrolled in a major.");

      final subjectsResponse = await supabase.from('subjects').select('id, name, hours').eq('major_id', majorId);
      
      if (mounted) {
        setState(() {
          final passedIds = takenSubjects.where((s) => s['status'] == 'passed').map((s) => s['subject']['id']).toSet();
          _allSubjects = List<Map<String, dynamic>>.from(subjectsResponse).where((s) => !passedIds.contains(s['id'])).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() { _isLoading = false; _errorMessage = "Error: ${e.toString()}"; });
      }
    }
  }

  void _recalculateAll() {
    double termQualityPoints = 0;
    int termHours = 0;
    for (final entry in _selectedSubjects) {
      termHours += entry.hours;
      termQualityPoints += (_getGradePoint(entry.mark) * entry.hours);
    }
    
    setState(() {
      _termHours = termHours;
      _termGpa = termHours > 0 ? termQualityPoints / termHours : 0.0;
    });
    _calculateProjectedGpa();
  }

  void _calculateProjectedGpa() {
    double termQualityPoints = 0;
    int termHours = 0;
    for (final entry in _selectedSubjects) {
      termHours += entry.hours;
      termQualityPoints += (_getGradePoint(entry.mark) * entry.hours);
    }
    
    final totalQualityPoints = _historicalQualityPoints + termQualityPoints;
    final totalHours = _historicalHours + termHours;

    setState(() {
      _projectedGpa = totalHours > 0 ? totalQualityPoints / totalHours : 0.0;
    });
  }

  double _getGradePoint(int? mark) {
    if (mark == null) return 0.0;
    if (mark >= 98) return 4.0;
    if (mark >= 95) return 3.75;
    if (mark >= 90) return 3.5;
    if (mark >= 85) return 3.25;
    if (mark >= 80) return 3.0;
    if (mark >= 75) return 2.75;
    if (mark >= 70) return 2.5;
    if (mark >= 65) return 2.25;
    if (mark >= 60) return 2.0;
    if (mark >= 55) return 1.75;
    if (mark >= 50) return 1.5;
    return 0.0;
  }
  
  void _showAddSubjectDialog() {
    int? subjectToAddId;
    
    final availableSubjects = _allSubjects.where((s) => !_selectedSubjects.any((ss) => ss.id == s['id'])).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: const Text("Add Subject to Term", style: TextStyle(color: AppColors.darkTextPrimary)),
        content: DropdownButtonFormField<int>(
          hint: const Text("Select a subject", style: TextStyle(color: AppColors.darkTextSecondary)),
          dropdownColor: AppColors.darkSurface,
          style: const TextStyle(color: AppColors.darkTextPrimary),
          items: availableSubjects.map((s) => DropdownMenuItem<int>(value: s['id'], child: Text(s['name']))).toList(),
          onChanged: (value) => subjectToAddId = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (subjectToAddId != null) {
                final subjectData = _allSubjects.firstWhere((s) => s['id'] == subjectToAddId);
                final newHours = _termHours + (subjectData['hours'] as int);
                
                if (newHours > 21) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot add subject. Total hours would exceed 21."), backgroundColor: AppColors.error));
                  return;
                }
                
                setState(() {
                  _selectedSubjects.add(SubjectEntry(id: subjectData['id'], name: subjectData['name'], hours: subjectData['hours']));
                });
                _recalculateAll();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        title: const Text("GPA Calculator"),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
              : Column(
                  children: [
                    _buildHeader(scaleConfig),
                    Expanded(
                      child: _selectedSubjects.isEmpty
                          ? _buildEmptyState()
                          : _buildSubjectsList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showAddSubjectDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.darkBackground),
        tooltip: "Add Subject",
      ),
    );
  }

  Widget _buildHeader(ScaleConfig scaleConfig) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: AppColors.darkBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderItem("Term GPA", _termGpa.toStringAsFixed(2), AppColors.primary, scaleConfig),
                _buildHeaderItem("Term Hours", "$_termHours / 21", AppColors.accent, scaleConfig),
              ],
            ),
            const Divider(height: 24, color: AppColors.darkSurface),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_graph, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text("Projected Cumulative GPA:", style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scaleText(14))),
                const Spacer(),
                Text(_projectedGpa.toStringAsFixed(2), style: TextStyle(color: AppColors.primary, fontSize: scaleConfig.scaleText(22), fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value, Color color, ScaleConfig scaleConfig) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scaleText(14))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: scaleConfig.scaleText(22), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_chart, size: 60, color: AppColors.darkTextSecondary),
          SizedBox(height: 16),
          Text("Add subjects to calculate your projected GPA.", style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      itemCount: _selectedSubjects.length,
      itemBuilder: (context, index) {
        final entry = _selectedSubjects[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: AppColors.darkBackground,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
                      Text("${entry.hours} Hours", style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: entry.markController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 3,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: "Mark (%)", labelStyle: TextStyle(fontSize: 12),
                      counterText: "", border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)
                    ),
                    onChanged: (value) {
                      final newMark = int.tryParse(value) ?? 0;
                      if (newMark >= 0 && newMark <= 100) {
                        entry.mark = newMark;
                        _recalculateAll();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _selectedSubjects[index].dispose();
                      _selectedSubjects.removeAt(index);
                    });
                    _recalculateAll();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}