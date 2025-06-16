import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';


class RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 0, 255, 174),        // Color of the checkmark
          checkColor: Colors.black,              // Color of the check itself
          side: const BorderSide(color: AppColors.primary), // Unchecked border
        ),
        const SizedBox(width: 2),
        const Text(
          "Remember Me",
          style: TextStyle(color: AppColors.darkTextPrimary), // Label color
        ),
      ],
    );
  }
}
