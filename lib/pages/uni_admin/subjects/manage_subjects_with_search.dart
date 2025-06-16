// lib/pages/uni_admin/subjects/search_subjects_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/uni_admin/subjects/add_subject.dart';
import 'package:unicurve/pages/uni_admin/subjects/manage_subjects_relationships.dart';
// Note: You might not need this file if you consolidate logic, but keeping for now.
import 'package:unicurve/pages/uni_admin/subjects/subjects_list_for_search_page.dart';

class SearchSubjectsPage extends StatefulWidget {
  final int majorId;
  const SearchSubjectsPage({super.key, required this.majorId});

  @override
  _SearchSubjectsPageState createState() => _SearchSubjectsPageState();
}

class _SearchSubjectsPageState extends State<SearchSubjectsPage> {
  final supabase = Supabase.instance.client;
  
  // Future holders for our data
  Future<List<Map<String, dynamic>>>? _subjectsFuture;
  Future<Map<int, String>>? _requirementsMapFuture;
  
  // State for search and UI
  List<Map<String, dynamic>> _allSubjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  final TextEditingController _searchController = TextEditingController();
  String? _majorName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch all data in initState
    _fetchAllData();
    _searchController.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _subjectsFuture = _fetchSubjects();
      _requirementsMapFuture = _fetchRequirementsMap();
    });
    // Fetch major name separately
    try {
      final majorResponse = await supabase.from('majors').select('name').eq('id', widget.majorId).single();
      if (mounted) {
        setState(() => _majorName = majorResponse['name']);
      }
    } catch (e) {
      _showSnackBar('Could not fetch major name: $e', isError: true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubjects() async {
    final response = await supabase
        .from('subjects')
        .select('id, name, code, hours, description, is_open, major_id, level, type')
        .eq('major_id', widget.majorId);
    
    // Store all subjects once fetched
    _allSubjects = List<Map<String, dynamic>>.from(response);
    _filteredSubjects = _allSubjects;
    return _allSubjects;
  }

  Future<Map<int, String>> _fetchRequirementsMap() async {
    final response = await supabase
        .from('major_requirements')
        .select('id, requirement_name')
        .eq('major_id', widget.majorId);
        
    return { for (var req in response) (req['id'] as int): req['requirement_name'] as String };
  }

  void _filterSubjects() {
    // This now runs on the already-fetched data, making it instant
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSubjects = _allSubjects;
      } else {
        _filteredSubjects = _allSubjects.where((subject) {
          // You could also search by type name here if needed
          return subject['name'].toString().toLowerCase().contains(query) ||
                 subject['code'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteSubject(int subjectId) async {
    // This function can remain the same, but it should refresh the data at the end
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Confirm Deletion', style: TextStyle(color: AppColors.darkTextPrimary)),
        content: const Text('Are you sure you want to delete this subject? This action cannot be undone.', style: TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.accent))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await supabase.from('subject_professors').delete().eq('subject_id', subjectId);
      await supabase.from('subject_relationships').delete().or('source_subject_id.eq.$subjectId,target_subject_id.eq.$subjectId');
      await supabase.from('subjects').delete().eq('id', subjectId);

      _showSnackBar('Subject deleted successfully');
      // Refresh all data
      _fetchAllData();

    } catch (e) {
      _showSnackBar('Error deleting subject: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editSubject(Map<String, dynamic> subject, Map<int, String> requirementsMap) async {
    final scaleConfig = context.scaleConfig;
    final nameController = TextEditingController(text: subject['name']);
    final codeController = TextEditingController(text: subject['code']);
    final hoursController = TextEditingController(text: subject['hours'].toString());
    final descriptionController = TextEditingController(text: subject['description']);
    bool isOpen = subject['is_open'] ?? false;
    int? level = subject['level'];
    int? typeId = subject['type']; // This is the ID

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(12))),
          title: Text('Edit Subject', style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: scaleConfig.scaleText(18))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Subject Name'), style: const TextStyle(color: AppColors.darkTextPrimary)),
                TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code'), style: const TextStyle(color: AppColors.darkTextPrimary)),
                TextField(controller: hoursController, decoration: const InputDecoration(labelText: 'Hours'), keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.darkTextPrimary)),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3, style: const TextStyle(color: AppColors.darkTextPrimary)),
                
                // NEW: Requirement Type Dropdown
                DropdownButtonFormField<int>(
                  value: typeId,
                  items: requirementsMap.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => typeId = value),
                  decoration: const InputDecoration(labelText: 'Requirement Type'),
                  dropdownColor: AppColors.darkBackground,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                ),

                CheckboxListTile(
                  title: const Text('Is Open', style: TextStyle(color: AppColors.darkTextPrimary)),
                  value: isOpen,
                  onChanged: (value) => setDialogState(() => isOpen = value ?? false),
                  activeColor: AppColors.accent,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.accent))),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedData = {
                    'name': nameController.text,
                    'code': codeController.text,
                    'hours': int.tryParse(hoursController.text) ?? 0,
                    'description': descriptionController.text,
                    'is_open': isOpen,
                    'level': level,
                    'type': typeId, // Save the integer ID
                  };

                  await supabase.from('subjects').update(updatedData).eq('id', subject['id']);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _showSnackBar('Subject updated successfully');
                    _fetchAllData(); // Refresh data
                  }
                } catch (e) {
                   if (mounted) {
                    Navigator.pop(context);
                    _showSnackBar('Error updating subject: $e', isError: true);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDetailsDialog(Map<String, dynamic> subject, Map<int, String> requirementsMap) {
    final scaleConfig = context.scaleConfig;
    // Use the map to get the display name for the type
    final String typeName = requirementsMap[subject['type']] ?? 'Uncategorized';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(16)), side: const BorderSide(color: AppColors.primaryDark, width: 1.5)),
        title: Text(subject['name']?.toString() ?? 'Unknown Subject', style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: scaleConfig.scaleText(20))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDetailRow(label: 'Code', value: subject['code']?.toString() ?? 'N/A', icon: Icons.code, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Hours', value: '${subject['hours'] ?? 0} hr', icon: Icons.access_time, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Level', value: subject['level']?.toString() ?? 'N/A', icon: Icons.trending_up, scaleConfig: scaleConfig),
              // CORE FIX: Display the correct name
              _buildDetailRow(label: 'Type', value: typeName, icon: Icons.category, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Open', value: subject['is_open'] == true ? 'Yes' : 'No', icon: subject['is_open'] == true ? Icons.check_circle : Icons.cancel, iconColor: subject['is_open'] == true ? AppColors.primary : AppColors.error, scaleConfig: scaleConfig),
              _buildDetailRow(label: 'Description', value: subject['description']?.toString() ?? 'No description', icon: Icons.description, isMultiLine: true, scaleConfig: scaleConfig),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Close', style: TextStyle(color: AppColors.darkBackground, fontSize: scaleConfig.scaleText(14), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({ required String label, required String value, required IconData icon, required ScaleConfig scaleConfig, bool isMultiLine = false, Color? iconColor }) {
     return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
      child: Card(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(12)), side: BorderSide(color: AppColors.primary.withOpacity(0.3))),
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary, size: scaleConfig.scale(20)),
          title: Text(label, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scaleText(15), fontWeight: FontWeight.w500)),
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
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      floatingActionButton: CustomFAB(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddSubjectBasicPage()))),
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        title: Text(_majorName ?? 'Manage Subjects', style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: scaleConfig.scaleText(18)), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.lan_outlined, color: AppColors.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageSubjectsRelationshipsPage(subjects: _allSubjects))),
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
                hintText: 'Search by name or code...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(12)), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: AppColors.darkTextPrimary),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: Future.wait([_subjectsFuture!, _requirementsMapFuture!]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found.', style: TextStyle(color: AppColors.darkTextSecondary)));
                }

                final requirementsMap = snapshot.data![1] as Map<int, String>;

                return SubjectsListBuilder(
                  subjects: _filteredSubjects,
                  isLoading: _isLoading,
                  // Pass the map to the detail and edit dialogs
                  onSubjectTap: (subject) => _showSubjectDetailsDialog(subject, requirementsMap),
                  onEditSubject: (subject) => _editSubject(subject, requirementsMap),
                  onDeleteSubject: _deleteSubject,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}