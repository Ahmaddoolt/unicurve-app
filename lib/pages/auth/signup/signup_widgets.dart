import 'package:flutter/material.dart';

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
    return DropdownButtonFormField(
      focusColor: const Color.fromARGB(255, 0, 255, 174),
      value: value,
      hint: const Text("Select University"),
      items: items.map<DropdownMenuItem<Map<String, dynamic>>>((uni) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: uni,
          child: Text(uni['name']),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a university' : null,
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
    return DropdownButtonFormField(
      value: value,
      hint: const Text("Select Major"),
      items: items.map<DropdownMenuItem<Map<String, dynamic>>>((major) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: major,
          child: Text(major['name']),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a major' : null,
    );
  }
}

class SignupButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SignupButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text("Sign Up"),
    );
  }
}