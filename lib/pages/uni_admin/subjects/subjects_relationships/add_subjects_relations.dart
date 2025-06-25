import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';

class AddSubjectRelationsPage extends StatefulWidget {
  final Subject subject;
  final int universityId;

  const AddSubjectRelationsPage({
    super.key,
    required this.subject,
    required this.universityId,
  });

  @override
  AddSubjectRelationsPageState createState() => AddSubjectRelationsPageState();
}

class AddSubjectRelationsPageState extends State<AddSubjectRelationsPage> {
  final supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _availableSubjects = [];
  final List<Map<String, dynamic>> _selectedRelationships = [];
  bool _isLoading = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final _formKey = GlobalKey<FormState>();
  int? _selectedSubjectId;
  String? _selectedType;

  final List<Map<String, String>> _relationshipTypes = [
    {'value': 'PREREQUISITE', 'label': 'add_relations_prerequisite'.tr},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAvailableSubjects();
    _fetchExistingRelationships();
  }

  Future<void> _fetchAvailableSubjects() async {
    setState(() => _isLoading = true);
    try {
      final majorsResponse = await supabase
          .from('majors')
          .select('id')
          .eq('university_id', widget.universityId);

      if (majorsResponse.isEmpty) {
        if (mounted) setState(() => _availableSubjects.clear());
        return;
      }

      final List<int> majorIds =
          majorsResponse.map((m) => m['id'] as int).toList();
      if (majorIds.isEmpty) {
        if (mounted) setState(() => _availableSubjects.clear());
        return;
      }

      final orFilter = majorIds.map((id) => 'major_id.eq.$id').join(',');

      final response = await supabase
          .from('subjects')
          .select('id, code, name')
          .or(orFilter)
          .neq('id', widget.subject.id!);

      if (mounted) {
        setState(() {
          _availableSubjects.clear();
          _availableSubjects.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_fetch_subjects'.trParams({
            'error': e.toString(),
          }),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExistingRelationships() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('subject_relationships')
          .select(
            'target_subject_id, relationship_type, subjects:target_subject_id (id, code, name)',
          )
          .eq('source_subject_id', widget.subject.id!);

      if (mounted) {
        setState(() {
          _selectedRelationships.clear();
          _selectedRelationships.addAll(
            response.map(
              (r) => {
                'subject_id': r['target_subject_id'],
                'type': r['relationship_type'],
                'subject': r['subjects'],
              },
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_fetch_relations'.trParams({
            'error': e.toString(),
          }),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addRelationship() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackbar('add_relations_error_select_all'.tr);
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final targetSubjectId = _selectedSubjectId!;
      final relationshipType = _selectedType!;

      final existingRelationship =
          await supabase
              .from('subject_relationships')
              .select('id')
              .eq('source_subject_id', widget.subject.id!)
              .eq('target_subject_id', targetSubjectId)
              .maybeSingle();

      if (existingRelationship != null) {
        _showErrorSnackbar('add_relations_error_exists'.tr);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await supabase.from('subject_relationships').insert({
        'source_subject_id': widget.subject.id,
        'target_subject_id': targetSubjectId,
        'relationship_type': relationshipType,
      });

      final addedSubjectDetails = _availableSubjects.firstWhere(
        (s) => s['id'] == targetSubjectId,
      );

      if (mounted) {
        setState(() {
          _selectedRelationships.insert(0, {
            'subject_id': targetSubjectId,
            'type': relationshipType,
            'subject': addedSubjectDetails,
          });
          _listKey.currentState?.insertItem(
            0,
            duration: const Duration(milliseconds: 300),
          );
          _formKey.currentState?.reset();
          _selectedSubjectId = null;
          _selectedType = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_add'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeRelationship(
    Map<String, dynamic> relationship,
    int index,
  ) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await supabase
          .from('subject_relationships')
          .delete()
          .eq('source_subject_id', widget.subject.id!)
          .eq('target_subject_id', relationship['subject_id'])
          .eq('relationship_type', relationship['type']);

      if (mounted) {
        final removedItem = _selectedRelationships.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) =>
              _buildRelationshipItem(context, removedItem, animation, index),
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_remove'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finish() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final countResponse =
          await supabase
              .from('subject_relationships')
              .select('id')
              .eq('source_subject_id', widget.subject.id!)
              .eq('relationship_type', 'PREREQUISITE')
              .count();

      final unlocksCount = countResponse.count;

      await supabase
          .from('subjects')
          .update({'priority': unlocksCount})
          .eq('id', widget.subject.id!);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'add_relations_success_finish'.tr,
              style: const TextStyle(color: AppColors.darkTextPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'add_relations_error_finish'.trParams({'error': e.toString()}),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          message,
          style: const TextStyle(color: AppColors.darkTextPrimary),
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
      backgroundColor: lighterColor,
      appBar: CustomAppBar(
        title: 'add_relations_page_title'.trParams({
          'code': widget.subject.code,
        }),
        centerTitle: true,
        backgroundColor: darkerColor,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  child: Card(
                    color: darkerColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        scaleConfig.scale(16),
                      ),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(scaleConfig.scale(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'add_relations_section_new_title'.tr,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: scaleConfig.scaleText(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          _buildRelationshipAdder(context, scaleConfig),
                          SizedBox(height: scaleConfig.scale(24)),
                          Text(
                            'add_relations_section_current_title'.tr,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: scaleConfig.scaleText(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          _selectedRelationships.isEmpty
                              ? Container(
                                padding: EdgeInsets.all(scaleConfig.scale(16)),
                                decoration: BoxDecoration(
                                  color: lighterColor,
                                  borderRadius: BorderRadius.circular(
                                    scaleConfig.scale(8),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'add_relations_no_relations_yet'.tr,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: scaleConfig.scaleText(15),
                                    ),
                                  ),
                                ),
                              )
                              : AnimatedList(
                                key: _listKey,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                initialItemCount: _selectedRelationships.length,
                                itemBuilder:
                                    (context, index, animation) =>
                                        _buildRelationshipItem(
                                          context,
                                          _selectedRelationships[index],
                                          animation,
                                          index,
                                        ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomActionBar(
                context,
                scaleConfig,
                darkerColor,
                lighterColor,
                primaryTextColor,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              // ignore: deprecated_member_use
              color: (darkerColor).withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelationshipAdder(
    BuildContext context,
    ScaleConfig scaleConfig,
  ) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _selectedSubjectId,
            isExpanded: true,
            decoration: _inputDecoration(
              'subject_label'.tr,
              Icons.book,
              scaleConfig,
            ),
            items:
                _availableSubjects.map((subject) {
                  return DropdownMenuItem<int>(
                    value: subject['id'] as int,
                    child: Text(
                      '${subject['code']} - ${subject['name']}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: scaleConfig.scaleText(15),
                      ),
                    ),
                  );
                }).toList(),
            onChanged:
                _isLoading
                    ? null
                    : (value) => setState(() => _selectedSubjectId = value),
            validator:
                (value) =>
                    value == null
                        ? 'add_relations_error_select_subject'.tr
                        : null,
          ),
          SizedBox(height: scaleConfig.scale(16)),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: _inputDecoration(
              'add_relations_type_label'.tr,
              Icons.link,
              scaleConfig,
            ),
            items:
                _relationshipTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(
                      type['label']!,
                      style: TextStyle(color: primaryTextColor),
                    ),
                  );
                }).toList(),
            onChanged:
                _isLoading
                    ? null
                    : (value) => setState(() => _selectedType = value),
            validator:
                (value) =>
                    value == null ? 'add_relations_error_select_type'.tr : null,
          ),
          SizedBox(height: scaleConfig.scale(16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _addRelationship,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                'add_relations_add_button'.tr,
                style: TextStyle(
                  fontSize: scaleConfig.scaleText(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    ScaleConfig scaleConfig,
    Color? darkerColor,
    Color? lighterColor,
    Color? primaryTextColor,
  ) {
    return Card(
      color: darkerColor,
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(16)).copyWith(
          bottom: scaleConfig.scale(16) + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lighterColor,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: scaleConfig.scale(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  ),
                ),
                child: Text(
                  'back_button'.tr,
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: scaleConfig.scale(16)),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showFinishConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: darkerColor,
                  padding: EdgeInsets.symmetric(
                    vertical: scaleConfig.scale(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  ),
                ),
                child: Text(
                  'finish_button'.tr,
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishConfirmationDialog() {
    final scaleConfig = context.scaleConfig;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: lighterColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            title: Text(
              'add_relations_confirm_finish_title'.tr,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: scaleConfig.scaleText(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'add_relations_confirm_finish_content'.tr,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: scaleConfig.scaleText(15),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          Navigator.pop(context);
                          _finish();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                  ),
                ),
                child: Text(
                  'add_relations_confirm_button'.tr,
                  style: TextStyle(
                    fontSize: scaleConfig.scaleText(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            actionsPadding: EdgeInsets.only(
              right: scaleConfig.scale(16),
              bottom: scaleConfig.scale(16),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    ScaleConfig scaleConfig,
  ) {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: secondaryTextColor),
      filled: true,
      fillColor: lighterColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: scaleConfig.scale(20),
      ),
    );
  }

  Widget _buildRelationshipItem(
    BuildContext context,
    Map<String, dynamic> relationship,
    Animation<double> animation,
    int index,
  ) {
    final scaleConfig = context.scaleConfig;
    final subject =
        relationship['subject'] as Map<String, dynamic>? ??
        {'code': 'DELETED', 'name': 'Subject'};
    final relationshipType = relationship['type'] as String;

    IconData getRelationshipIcon(String type) {
      switch (type) {
        case 'PREREQUISITE':
          return Icons.key;
        case 'COREQUISITE':
          return Icons.sync_alt;
        default:
          return Icons.link;
      }
    }

    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
          child: Card(
            color: lighterColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
              side: BorderSide(
                // ignore: deprecated_member_use
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            elevation: 1,
            child: ListTile(
              leading: Icon(
                getRelationshipIcon(relationshipType),
                color: AppColors.primary,
                size: scaleConfig.scale(20),
              ),
              title: Text(
                '${subject['code']} - ${subject['name']}',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: scaleConfig.scaleText(15),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _relationshipTypes.firstWhere(
                  (t) => t['value'] == relationshipType,
                  orElse: () => {'label': relationshipType},
                )['label']!,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: scaleConfig.scaleText(14),
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_forever,
                  color: AppColors.error,
                  size: scaleConfig.scale(20),
                ),
                onPressed:
                    _isLoading
                        ? null
                        : () => _removeRelationship(relationship, index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
