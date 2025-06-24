import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class EditSubjectDialog extends StatefulWidget {
  final Map<String, dynamic> subject;

  const EditSubjectDialog({super.key, required this.subject});

  @override
  EditSubjectDialogState createState() => EditSubjectDialogState();
}

class EditSubjectDialogState extends State<EditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  late String _code;
  late String _name;
  String? _description;
  late int _hours;
  late bool _isOpen;
  late int _level;
  String? _type;
  List<Map<String, dynamic>> _majors = [];
  int? _majorId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _code = widget.subject['code'];
    _name = widget.subject['name'];
    _description = widget.subject['description'];
    _hours = widget.subject['hours'];
    _isOpen = widget.subject['is_open'] ?? false;
    _level = widget.subject['level'];
    _type = widget.subject['type'];
    _majorId = widget.subject['major_id'];
    _fetchMajors();
  }

  Future<void> _fetchMajors() async {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    try {
      final response = await supabase.from('majors').select('id, name');
      if (mounted) {
        setState(() {
          _majors = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'add_subject_error_fetch_majors'.trParams({
                'error': e.toString(),
              }),
              style: TextStyle(
                color: primaryTextColor,
                fontSize: context.scaleConfig.scaleText(14),
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final updatedSubject = {
          'code': _code,
          'name': _name,
          'description': _description,
          'hours': _hours,
          'is_open': _isOpen,
          'major_id': _majorId,
          'level': _level,
          'type': _type,
        };

        await supabase
            .from('subjects')
            .update(updatedSubject)
            .eq('id', widget.subject['id']);

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context, {...widget.subject, ...updatedSubject});
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'edit_subject_error_update'.trParams({'error': e.toString()}),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: context.scaleConfig.scaleText(14),
                ),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return AlertDialog(
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
        child: SizedBox(
          width: scaleConfig.widthPercentage(0.8),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _code,
                  decoration: InputDecoration(
                    labelText: 'add_subject_code_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? 'error_field_required'.tr
                              : null,
                  onSaved: (value) => _code = value!,
                ),
                SizedBox(height: scaleConfig.scale(12)),
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(
                    labelText: 'add_subject_name_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? 'error_field_required'.tr
                              : null,
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: scaleConfig.scale(12)),
                TextFormField(
                  initialValue: _description,
                  decoration: InputDecoration(
                    labelText: 'add_subject_desc_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _description = value,
                ),
                SizedBox(height: scaleConfig.scale(12)),
                TextFormField(
                  initialValue: _hours.toString(),
                  decoration: InputDecoration(
                    labelText: 'add_subject_hours_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'error_field_required'.tr;
                    }
                    final hours = int.tryParse(value!);
                    return hours == null || hours <= 0
                        ? 'edit_subject_error_valid_hours'.tr
                        : null;
                  },
                  onSaved: (value) => _hours = int.parse(value!),
                ),
                SizedBox(height: scaleConfig.scale(12)),
                SwitchListTile(
                  title: Text(
                    'add_subject_is_open_label'.tr,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                  ),
                  value: _isOpen,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => _isOpen = value),
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'add_subject_major_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  dropdownColor: lighterColor,
                  value: _majorId,
                  items:
                      _majors.map((major) {
                        return DropdownMenuItem<int>(
                          value: int.parse(major['id'].toString()),
                          child: Text(
                            major['name'],
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => _majorId = value),
                  onSaved: (value) => _majorId = value,
                ),
                SizedBox(height: scaleConfig.scale(12)),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'add_subject_level_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  dropdownColor: lighterColor,
                  value: _level,
                  items:
                      List.generate(8, (index) => index + 1).map((level) {
                        return DropdownMenuItem<int>(
                          value: level,
                          child: Text(
                            'add_subject_level_unit'.trParams({
                              'level': '$level',
                            }),
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                        );
                      }).toList(),
                  validator:
                      (value) =>
                          value == null ? 'error_field_required'.tr : null,
                  onChanged: (value) => setState(() => _level = value!),
                  onSaved: (value) => _level = value!,
                ),
                SizedBox(height: scaleConfig.scale(12)),
                TextFormField(
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: 'add_subject_req_type_label'.tr,
                    labelStyle: TextStyle(
                      color: secondaryTextColor,
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      borderSide: BorderSide(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: scaleConfig.scaleText(14),
                  ),
                  onSaved: (value) => _type = value,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'cancel'.tr,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: scaleConfig.scaleText(14),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: primaryTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
            ),
          ),
          child: Text(
            'save_button'.tr,
            style: TextStyle(fontSize: scaleConfig.scaleText(14)),
          ),
        ),
      ],
    );
  }
}
