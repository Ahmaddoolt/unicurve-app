// lib/pages/auth/login/login_widgets/rember_checkbox.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    final theme = Theme.of(context);
    // --- THE KEY FIX IS HERE: Make the entire row tappable ---
    return InkWell(
      onTap: () {
        onChanged?.call(!value);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- FIX: Styled to match the modern theme ---
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              checkColor:
                  Colors.white, // White check looks good on the gradient
              side: BorderSide(
                color: theme.textTheme.bodyMedium?.color ?? Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'remember_me_label'.tr,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
