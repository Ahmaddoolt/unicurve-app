import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';

class AddSubjectRelationsPage extends StatefulWidget {
  final Subject subject;

  const AddSubjectRelationsPage({super.key, required this.subject});

  @override
  AddSubjectRelationsPageState createState() => AddSubjectRelationsPageState();
}

class AddSubjectRelationsPageState extends State<AddSubjectRelationsPage> {
  final supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _availableSubjects = [];
  final List<Map<String, dynamic>> _selectedRelationships = [];
  bool _isLoading = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // State variables for the form
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectId;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _fetchAvailableSubjects();
    _fetchExistingRelationships();
  }

  Future<void> _fetchAvailableSubjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('subjects')
          .select('id, code, name')
          .neq('id', widget.subject.id!);
      if (mounted) {
        setState(() {
          _availableSubjects.clear();
          _availableSubjects.addAll(List<Map<String, dynamic>>.from(response));
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error fetching subjects: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExistingRelationships() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('subject_relationships')
          .select('target_subject_id, relationship_type, subjects:target_subject_id (id, code, name)')
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
      if (mounted) _showErrorSnackbar('Error fetching relationships: $e');
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addRelationship() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackbar('Please select both a subject and a relationship type');
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final targetSubjectId = _selectedSubjectId!;
      final relationshipType = _selectedType!;

      final existingRelationship = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', widget.subject.id!)
          .eq('target_subject_id', targetSubjectId)
          .eq('relationship_type', relationshipType)
          .maybeSingle();

      if (existingRelationship != null) {
        _showErrorSnackbar('This relationship already exists');
        return;
      }

      await supabase.from('subject_relationships').insert({
        'source_subject_id': widget.subject.id,
        'target_subject_id': targetSubjectId,
        'relationship_type': relationshipType,
      });
      
      final addedSubjectDetails = _availableSubjects.firstWhere((s) => s['id'].toString() == targetSubjectId);

      if (mounted) {
        setState(() {
          _selectedRelationships.insert(0, {
            'subject_id': int.tryParse(targetSubjectId),
            'type': relationshipType,
            'subject': addedSubjectDetails,
          });
          _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
          
          _formKey.currentState?.reset();
          _selectedSubjectId = null;
          _selectedType = null;
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error adding relationship: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeRelationship(Map<String, dynamic> relationship, int index) async {
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
          (context, animation) => _buildRelationshipItem(removedItem, animation),
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error removing relationship: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finish() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      // --- MODIFIED LOGIC ---
      // Priority is now calculated based on the number of subjects this one is a prerequisite for.
      final response = await supabase
          .from('subject_relationships')
          .select('id')
          .eq('source_subject_id', widget.subject.id!)
          .eq('relationship_type', 'PREREQUISITE'); // Changed from 'UNLOCKS'

      final unlocksCount = response.length; 

      await supabase
          .from('subjects')
          .update({'priority': unlocksCount})
          .eq('id', widget.subject.id!);

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Subject and relationships saved successfully',
              style: TextStyle(color: AppColors.darkTextPrimary),
            ),
          ),
        );
      }
    } catch (e) {
       if (mounted) _showErrorSnackbar('Error finalizing subject: $e');
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(message, style: const TextStyle(color: AppColors.darkTextPrimary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: CustomAppBar(
        title: 'Relationships for ${widget.subject.code}',
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                  child: Card(
                    color: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(scaleConfig.scale(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Relationship',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: scaleConfig.scaleText(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          _buildRelationshipAdder(scaleConfig),
                          SizedBox(height: scaleConfig.scale(24)),
                          Text(
                            'Current Relationships',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: scaleConfig.scaleText(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: scaleConfig.scale(16)),
                          _selectedRelationships.isEmpty
                              ? Container(
                                  padding: EdgeInsets.all(scaleConfig.scale(16)),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No relationships added yet',
                                      style: TextStyle(
                                        color: AppColors.darkTextSecondary,
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
                                  itemBuilder: (context, index, animation) =>
                                      _buildRelationshipItem(
                                          _selectedRelationships[index], animation),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Card(
                color: AppColors.darkBackground,
                elevation: 4,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(scaleConfig.scale(16)).copyWith(
                    bottom: scaleConfig.scale(16) + MediaQuery.of(context).padding.bottom
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Back',
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkSurface,
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(16)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(scaleConfig.scale(12))),
                            ),
                            child: Text('Back', style: TextStyle(fontSize: scaleConfig.scaleText(16), fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      SizedBox(width: scaleConfig.scale(16)),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Finish',
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              backgroundColor:
                                                  AppColors.darkSurface,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      scaleConfig.scale(16),
                                                    ),
                                                side: const BorderSide(
                                                  color: AppColors.primary,
                                                  width: 1.5,
                                                ),
                                              ),
                                              title: Text(
                                                'Confirm',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.darkTextPrimary,
                                                  fontSize: scaleConfig
                                                      .scaleText(18),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to finish and save these relationships?',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.darkTextPrimary,
                                                  fontSize: scaleConfig
                                                      .scaleText(15),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      _isLoading
                                                          ? null
                                                          : () => Navigator.pop(
                                                            context,
                                                          ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors
                                                              .darkTextSecondary,
                                                      fontSize: scaleConfig
                                                          .scaleText(14),
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed:
                                                      _isLoading
                                                          ? null
                                                          : () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _finish();
                                                          },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        AppColors
                                                            .darkBackground, 
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            scaleConfig.scale(
                                                              8,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Confirm',
                                                    style: TextStyle(
                                                      fontSize: scaleConfig
                                                          .scaleText(14),
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.darkBackground,
                              padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(16)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(scaleConfig.scale(12))),
                            ),
                            child: Text('Finish', style: TextStyle(fontSize: scaleConfig.scaleText(16), fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildRelationshipAdder(ScaleConfig scaleConfig) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: _inputDecoration('Subject*', Icons.book, scaleConfig),
            items: _availableSubjects.map((subject) {
              return DropdownMenuItem<String>(
                value: subject['id'].toString(),
                child: Text(
                  '${subject['code']} - ${subject['name']}',
                  style: TextStyle(
                      color: AppColors.darkTextPrimary, fontSize: scaleConfig.scaleText(15)),
                ),
              );
            }).toList(),
            onChanged: _isLoading ? null : (value) => setState(() => _selectedSubjectId = value),
            validator: (value) => value == null ? 'Please select a subject' : null,
          ),
          SizedBox(height: scaleConfig.scale(16)),
          // --- MODIFIED DROPDOWN ---
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: _inputDecoration('Relationship Type*', Icons.link, scaleConfig),
            items: const [
              DropdownMenuItem(value: 'PREREQUISITE', child: Text('Prerequisite', style: TextStyle(color: AppColors.darkTextPrimary))),
            ],
            onChanged: _isLoading ? null : (value) => setState(() => _selectedType = value),
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
          SizedBox(height: scaleConfig.scale(16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addRelationship,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.darkBackground,
                padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(16)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scaleConfig.scale(12))),
              ),
              child: Text('Add Relationship', style: TextStyle(fontSize: scaleConfig.scaleText(16), fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ScaleConfig scaleConfig) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.darkTextSecondary),
      hintText: 'Select...',
      hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.5)),
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
        borderSide: BorderSide(color: AppColors.primaryDark),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: scaleConfig.scale(16),
        vertical: scaleConfig.scale(12),
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: scaleConfig.scale(20)),
    );
  }

  Widget _buildRelationshipItem(Map<String, dynamic> relationship, Animation<double> animation) {
    final scaleConfig = context.scaleConfig;
    final subject = relationship['subject'] as Map<String, dynamic>? ?? 
                    {'code': 'DELETED', 'name': 'Subject', 'id': relationship['subject_id']};

    IconData getRelationshipIcon(String type) {
      // Kept old types to avoid breaking UI for existing data
      switch (type) {
        case 'PREREQUISITE': return Icons.lock;
        case 'COREQUISITE': return Icons.sync;
        case 'UNLOCKS': return Icons.lock_open;
        default: return Icons.link;
      }
    }

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
          child: Card(
            color: AppColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
              side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
            ),
            elevation: 1,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(16), vertical: scaleConfig.scale(8)),
              leading: Icon(getRelationshipIcon(relationship['type']), color: AppColors.primary, size: scaleConfig.scale(20)),
              title: Text(
                '${subject['code']} - ${subject['name']}',
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: scaleConfig.scaleText(15),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                relationship['type'],
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scaleText(14)),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_forever, color: AppColors.error, size: scaleConfig.scale(20)),
                onPressed: _isLoading ? null : () {
                  final index = _selectedRelationships.indexOf(relationship);
                   if (index != -1) {
                    _removeRelationship(relationship, index);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}