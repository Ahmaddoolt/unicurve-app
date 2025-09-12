import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

const double kPadding = 16.0;
const double kCardRadius = 12.0;

void showFeedbackSnackbar(
  BuildContext context,
  String message, {
  bool isError = false,
  int durationSeconds = 3,
}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius * 0.8),
      ),
      margin: const EdgeInsets.all(kPadding),
      duration: Duration(seconds: durationSeconds),
    ),
  );
}
