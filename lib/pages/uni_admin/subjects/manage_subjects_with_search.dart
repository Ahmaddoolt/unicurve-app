import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/uni_admin/subjects/add_subject.dart';
import 'package:unicurve/pages/uni_admin/subjects/manage_subjects_relationships.dart';
import 'package:unicurve/pages/uni_admin/subjects/subjects_list_for_search_page.dart';

class SearchSubjectsPage extends StatefulWidget {
  final int majorId;
  const SearchSubjectsPage({super.key, required this.majorId});

  @override
  SearchSubjectsPageState createState() => SearchSubjectsPageState();
}

class SearchSubjectsPageState extends State<SearchSubjectsPage> {
  final supabase = Supabase.instance.client;
  Future<List<dynamic>>? _dataFutures;
  List<Map<String, dynamic>> _allSubjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  final TextEditingController _searchController = TextEditingController();
  String? _majorName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _searchController.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final majorResponse =
          await supabase
              .from('majors')
              .select('name')
              .eq('id', widget.majorId)
              .single();

      if (mounted) {
        setState(() {
          _majorName = majorResponse['name'];
          _dataFutures = Future.wait([
            _fetchSubjectsAndProfessors(),
            _fetchRequirementsMap(),
          ]);
        });
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(context, 'error_wifi'.tr, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubjectsAndProfessors() async {
    final response = await supabase
        .from('subjects')
        .select(
          'id, name, code, hours, description, is_open, major_id, level, type, subject_professors(professors(name))',
        )
        .eq('major_id', widget.majorId)
        .order('name', ascending: true);

    _allSubjects = List<Map<String, dynamic>>.from(response);
    _filteredSubjects = _allSubjects;
    return _allSubjects;
  }

  Future<Map<int, String>> _fetchRequirementsMap() async {
    final response = await supabase
        .from('major_requirements')
        .select('id, requirement_name')
        .eq('major_id', widget.majorId);
    return {
      for (var req in response)
        (req['id'] as int): req['requirement_name'] as String,
    };
  }

  void _filterSubjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects =
          _allSubjects.where((subject) {
            final nameMatch = subject['name'].toString().toLowerCase().contains(
              query,
            );
            final codeMatch = subject['code'].toString().toLowerCase().contains(
              query,
            );

            final professorsList =
                (subject['subject_professors'] as List?) ?? [];
            final professorMatch = professorsList.any((profLink) {
              final prof = profLink['professors'];
              return prof != null &&
                  prof['name'].toString().toLowerCase().contains(query);
            });

            return nameMatch || codeMatch || professorMatch;
          }).toList();
    });
  }

  Future<void> _deleteSubject(Map<String, dynamic> subject) async {
    final int? subjectId = subject['id'];
    if (subjectId == null) {
      showFeedbackSnackbar(
        context,
        'delete_subject_error_invalid'.tr,
        isError: true,
      );
      return;
    }

    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: lighterColor,
            title: Text(
              'manage_subjects_delete_title'.tr,
              style: TextStyle(color: primaryTextColor),
            ),
            content: Text(
              'delete_subject_confirm'.trParams({'name': subject['name']}),
              style: TextStyle(color: secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'delete_button'.tr,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      await supabase
          .from('subject_professors')
          .delete()
          .eq('subject_id', subjectId);
      await supabase
          .from('subject_relationships')
          .delete()
          .or(
            'source_subject_id.eq.$subjectId,target_subject_id.eq.$subjectId',
          );
      await supabase.from('subjects').delete().eq('id', subjectId);

      if (mounted) {
        showFeedbackSnackbar(context, 'manage_subjects_delete_success'.tr);
      }
      await _fetchAllData();
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(context, 'error_wifi'.tr, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editSubject(
    Map<String, dynamic> subject,
    Map<int, String> requirementsMap,
  ) async {
    final scaleConfig = context.scaleConfig;
    final nameController = TextEditingController(text: subject['name']);
    final codeController = TextEditingController(text: subject['code']);
    final hoursController = TextEditingController(
      text: subject['hours'].toString(),
    );
    final descriptionController = TextEditingController(
      text: subject['description'],
    );
    bool isOpen = subject['is_open'] ?? false;
    int? typeId = subject['type'];
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: lighterColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  ),
                  title: Text(
                    'edit_subject_dialog_title'.tr,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: scaleConfig.scaleText(18),
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'add_subject_name_label'.tr,
                          ),
                          style: TextStyle(color: primaryTextColor),
                        ),
                        TextField(
                          controller: codeController,
                          decoration: InputDecoration(
                            labelText: 'add_subject_code_label'.tr,
                          ),
                          style: TextStyle(color: primaryTextColor),
                        ),
                        TextField(
                          controller: hoursController,
                          decoration: InputDecoration(
                            labelText: 'add_subject_hours_label'.tr,
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: primaryTextColor),
                        ),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'add_subject_desc_label'.tr,
                          ),
                          maxLines: 3,
                          style: TextStyle(color: primaryTextColor),
                        ),
                        DropdownButtonFormField<int>(
                          value: typeId,
                          items:
                              requirementsMap.entries
                                  .map(
                                    (entry) => DropdownMenuItem<int>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setDialogState(() => typeId = value),
                          decoration: InputDecoration(
                            labelText: 'add_subject_req_type_label'.tr,
                          ),
                          dropdownColor: darkerColor,
                          style: TextStyle(color: primaryTextColor),
                        ),
                        CheckboxListTile(
                          title: Text(
                            'add_subject_is_open_label'.tr,
                            style: TextStyle(color: primaryTextColor),
                          ),
                          value: isOpen,
                          onChanged:
                              (value) =>
                                  setDialogState(() => isOpen = value ?? false),
                          activeColor: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await supabase
                              .from('subjects')
                              .update({
                                'name': nameController.text,
                                'code': codeController.text,
                                'hours':
                                    int.tryParse(hoursController.text) ?? 0,
                                'description': descriptionController.text,
                                'is_open': isOpen,
                                'type': typeId,
                              })
                              .eq('id', subject['id']);
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                            showFeedbackSnackbar(
                              // ignore: use_build_context_synchronously
                              context,
                              'manage_subjects_update_success'.tr,
                            );
                            await _fetchAllData();
                          }
                        } catch (e) {
                          if (mounted) {
                            showFeedbackSnackbar(
                              // ignore: use_build_context_synchronously
                              context,
                              'edit_subject_error_update'.trParams({
                                'error': e.toString(),
                              }),
                              isError: true,
                            );
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text('save_button'.tr),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showSubjectDetailsDialog(
    Map<String, dynamic> subject,
    Map<int, String> requirementsMap,
  ) {
    final scaleConfig = context.scaleConfig;
    final String typeName =
        requirementsMap[subject['type']] ?? 'uncategorized_label'.tr;
    final List<dynamic> professorLinks = subject['subject_professors'] ?? [];
    final List<String> professorNames =
        professorLinks
            .map((link) => link['professors']['name'] as String)
            .toList();

    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: darkerColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
              side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
            ),
            title: Text(
              subject['name']?.toString() ?? 'unknown_subject'.tr,
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: scaleConfig.scaleText(20),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildDetailRow(
                    label: 'code_label'.tr,
                    value: subject['code']?.toString() ?? 'not_available'.tr,
                    icon: Icons.code,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    label: 'add_subject_hours_label'.tr,
                    value: 'hours_label'.trParams({
                      'hours': '${subject['hours'] ?? 0}',
                    }),
                    icon: Icons.access_time,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    label: 'level_label'.tr,
                    value: subject['level']?.toString() ?? 'not_available'.tr,
                    icon: Icons.trending_up,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    label: 'type_label'.tr,
                    value: typeName,
                    icon: Icons.category,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    label: 'open_for_reg_label'.tr,
                    value: subject['is_open'] == true ? 'yes'.tr : 'no'.tr,
                    icon:
                        subject['is_open'] == true
                            ? Icons.check_circle
                            : Icons.cancel,
                    iconColor:
                        subject['is_open'] == true
                            ? AppColors.primary
                            : AppColors.error,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    label: 'description_label'.tr,
                    value:
                        subject['description']?.toString() ??
                        'no_description_provided'.tr,
                    icon: Icons.description,
                    isMultiLine: true,
                    scaleConfig: scaleConfig,
                  ),
                  _buildDetailRow(
                    label: 'professors_label'.tr,
                    value:
                        professorNames.isNotEmpty
                            ? professorNames.join(', ')
                            : 'no_professors_listed'.tr,
                    icon: Icons.person_search,
                    isMultiLine: true,
                    scaleConfig: scaleConfig,
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'close_button'.tr,
                  style: TextStyle(
                    color: darkerColor,
                    fontSize: scaleConfig.scaleText(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required ScaleConfig scaleConfig,
    bool isMultiLine = false,
    Color? iconColor,
  }) {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
      child: Card(
        color: lighterColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
          // ignore: deprecated_member_use
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: scaleConfig.scale(20),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: scaleConfig.scaleText(15),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            value,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: scaleConfig.scaleText(15),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      floatingActionButton: CustomFAB(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => AddSubjectBasicPage()),
          );
          if (result == true) {
            await _fetchAllData();
          }
        },
      ),
      backgroundColor: lighterColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: darkerColor,
        title: Text(
          _majorName ?? 'admin_manage_subjects'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: scaleConfig.scaleText(18),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lan_outlined, color: AppColors.primary),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ManageSubjectsRelationshipsPage(
                          subjects: _allSubjects,
                        ),
                  ),
                ),
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
                hintText: 'search_subjects_hint'.tr,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: darkerColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: primaryTextColor),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _dataFutures,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'error_generic'.trParams({
                        'error': snapshot.error.toString(),
                      }),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.isEmpty ||
                    (snapshot.data![0] as List).isEmpty) {
                  return Center(
                    child: Text(
                      'no_data_found'.tr,
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  );
                }
                final requirementsMap = snapshot.data![1] as Map<int, String>;
                return SubjectsListBuilder(
                  subjects: _filteredSubjects,
                  onSubjectTap:
                      (subject) =>
                          _showSubjectDetailsDialog(subject, requirementsMap),
                  onEditSubject:
                      (subject) => _editSubject(subject, requirementsMap),
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
