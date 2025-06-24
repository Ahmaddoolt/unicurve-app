import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UniversityDropdown extends StatelessWidget {
  final Map<String, dynamic>? value;
  final List<dynamic> items;
  final ValueChanged<dynamic>? onChanged;

  const UniversityDropdown({
    super.key,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: value,
      hint: Text('select_university_hint'.tr),
      isExpanded: true,
      items:
          items.map<DropdownMenuItem<Map<String, dynamic>>>((uni) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: uni,
              child: Text(
                '${uni['name']} (${uni['short_name']})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'error_select_university'.tr : null,
    );
  }
}

class MajorDropdown extends StatelessWidget {
  final Map<String, dynamic>? value;
  final List<dynamic> items;
  final ValueChanged<dynamic>? onChanged;

  const MajorDropdown({
    super.key,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: value,
      hint: Text('select_major_hint'.tr),
      isExpanded: true,
      items:
          items.map<DropdownMenuItem<Map<String, dynamic>>>((major) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: major,
              child: Text(major['name'], overflow: TextOverflow.ellipsis),
            );
          }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'error_select_major'.tr : null,
    );
  }
}
