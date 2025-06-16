// lib/pages/student/student_subjects_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/student_curriculum_tree_page.dart';

class StudentSubjectsPage extends StatefulWidget {
  const StudentSubjectsPage({super.key});

  @override
  _StudentSubjectsPageState createState() => _StudentSubjectsPageState();
}

class _StudentSubjectsPageState extends State<StudentSubjectsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  
  // NEW: A map to hold requirement ID -> requirement name
  Map<int, String> _requirementsMap = {};

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _majorName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudentMajorAndSubjects();
    _searchController.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentMajorAndSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      final studentResponse = await supabase
          .from('students')
          .select('major_id, majors(name)')
          .eq('user_id', userId)
          .single();

      final majorId = studentResponse['major_id'];
      if (majorId == null) {
        throw Exception("You are not enrolled in a major.");
      }
      
      final majorData = studentResponse['majors'];
      final majorName = majorData != null ? majorData['name'] as String? : 'Your Major';
      
      // Use Future.wait to run queries in parallel for better performance
      final results = await Future.wait([
        // Query 1: Fetch subjects
        supabase
            .from('subjects')
            .select('id, name, code, hours, description, is_open, level, type')
            .eq('major_id', majorId),
        
        // Query 2: Fetch requirement names
        supabase
            .from('major_requirements')
            .select('id, requirement_name')
            .eq('major_id', majorId),
      ]);
      
      final subjectsResponse = results[0] as List<dynamic>;
      final requirementsResponse = results[1] as List<dynamic>;

      // Create the map for easy lookup
      final requirementsMap = {
        for (var req in requirementsResponse) (req['id'] as int): req['requirement_name'] as String
      };

      if (mounted) {
        setState(() {
          _majorName = majorName;
          _subjects = List<Map<String, dynamic>>.from(subjectsResponse);
          _filteredSubjects = _subjects;
          _requirementsMap = requirementsMap; // Store the map
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
          _showSnackBar(_errorMessage!, isError: true);
        });
      }
    }
  }

  void _filterSubjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects = _subjects.where((subject) {
        final name = subject['name']?.toString().toLowerCase() ?? '';
        final code = subject['code']?.toString().toLowerCase() ?? '';
        // Also search by requirement type name
        final typeName = _requirementsMap[subject['type']]?.toLowerCase() ?? '';

        return name.contains(query) || code.contains(query) || typeName.contains(query);
      }).toList();
    });
  }

  void _showSubjectDetailsDialog(Map<String, dynamic> subject) {
    final scaleConfig = context.scaleConfig;
    // CORE FIX: Look up the name from the map using the subject's type ID
    final String typeName = _requirementsMap[subject['type']] ?? 'Uncategorized';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
        title: Center(
          child: Text(
            subject['name']?.toString() ?? 'Subject Details',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: scaleConfig.scaleText(20),
            ),
          ),
        ),
        contentPadding: EdgeInsets.all(scaleConfig.scale(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDetailRow(label: 'Code', value: subject['code']?.toString() ?? 'N/A', icon: Icons.code, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Hours', value: '${subject['hours'] ?? 0} hr', icon: Icons.access_time, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Level', value: subject['level']?.toString() ?? 'N/A', icon: Icons.trending_up, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Type', value: typeName, icon: Icons.category, scaleConfig: scaleConfig), // Display the looked-up name
              _buildDetailRow(
                label: 'Open for Registration',
                value: subject['is_open'] == true ? 'Yes' : 'No',
                icon: subject['is_open'] == true ? Icons.check_circle : Icons.cancel,
                iconColor: subject['is_open'] == true ? AppColors.primary : AppColors.error,
                scaleConfig: scaleConfig
              ),
              _buildDetailRow(label: 'Description', value: subject['description']?.toString() ?? 'No description provided.', icon: Icons.description, isMultiLine: true, scaleConfig: scaleConfig),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, required ScaleConfig scaleConfig, required IconData icon, bool isMultiLine = false, Color? iconColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(6)),
      child: Card(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        ),
        elevation: 0,
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary, size: scaleConfig.scale(22)),
          title: Text(label, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scaleText(14), fontWeight: FontWeight.w500)),
          subtitle: Text(value, style: TextStyle(color: AppColors.darkTextPrimary, fontSize: scaleConfig.scaleText(15), fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.darkTextPrimary)),
        backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        title: Text(
          _majorName != null ? '$_majorName Subjects' : 'My Subjects',
          style: TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(18),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_tree_outlined, color: AppColors.primary, size: scaleConfig.scale(22)),
            tooltip: 'View My Curriculum Plan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentCurriculumTreePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or type...',
                hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.darkTextPrimary),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                    : _filteredSubjects.isEmpty
                        ? Center(child: Text('No subjects found.', style: TextStyle(color: AppColors.darkTextSecondary)))
                        : RefreshIndicator(
                            onRefresh: _fetchStudentMajorAndSubjects,
                            color: AppColors.primary,
                            backgroundColor: AppColors.darkBackground,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(8)),
                              itemCount: _filteredSubjects.length,
                              itemBuilder: (context, index) {
                                final subject = _filteredSubjects[index];
                                return Card(
                                  color: AppColors.darkBackground,
                                  margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4), horizontal: scaleConfig.scale(8)),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(color: AppColors.primary, width: 1.0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(subject['name'] ?? 'No Name', style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
                                    subtitle: Text(subject['code'] ?? 'No Code', style: const TextStyle(color: AppColors.darkTextSecondary)),
                                    trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                                    onTap: () => _showSubjectDetailsDialog(subject),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}