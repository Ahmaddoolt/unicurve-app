// lib/pages/uni_admin/professors/views/professor_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart'; // --- FIX: Import the snackbar utility ---
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/providers/professors_provider.dart';

class ProfessorDetailsDialog extends ConsumerStatefulWidget {
  final Professor professor;
  final int? majorId;

  const ProfessorDetailsDialog({
    super.key,
    required this.professor,
    required this.majorId,
  });

  @override
  ProfessorDetailsDialogState createState() => ProfessorDetailsDialogState();
}

class ProfessorDetailsDialogState
    extends ConsumerState<ProfessorDetailsDialog> {
  List<Subject> _canTeachSubjects = [];
  String? _majorName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(professorsProvider(widget.majorId!).notifier);
      _majorName = await notifier.supabaseService
          .fetchMajorName(widget.professor.majorId);
      final details = await notifier.fetchProfessorDetails(widget.professor);

      if (mounted) {
        setState(() {
          _canTeachSubjects = details['canTeachSubjects'] as List<Subject>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop(); // Close dialog on error

        // --- THE FIX IS HERE: Use the global showFeedbackSnackbar function ---
        showFeedbackSnackbar(
          context,
          'prof_error_fetch_details'.trParams({'error': e.toString()}),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final primaryTextColor = theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: GlassLoadingOverlay(
        isLoading: _isLoading,
        child: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: scaleConfig.scale(340),
              maxHeight: scaleConfig.scale(450),
            ),
            child: Padding(
              padding: EdgeInsets.all(scaleConfig.scale(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.professor.name ?? 'prof_details_unknown_prof'.tr,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontSize: scaleConfig.scaleText(20)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'prof_details_major_label_with_name'
                        .trParams({'majorName': _majorName ?? '...'}),
                    style: theme.textTheme.bodyMedium,
                  ),
                  Divider(
                      height: scaleConfig.scale(24), color: theme.dividerColor),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'prof_details_can_teach_title'.tr,
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: scaleConfig.scale(8)),
                          _canTeachSubjects.isEmpty
                              ? Text(
                                  'prof_details_no_subjects_available'.tr,
                                  style: TextStyle(color: secondaryTextColor),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _canTeachSubjects.map((subject) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: scaleConfig.scale(4)),
                                      child: Text(
                                        '• ${subject.name} (${subject.code})',
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: scaleConfig.scaleText(14),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(24)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'close_button'.tr,
                      gradient: AppColors
                          .primaryGradient, // Use the gradient property
                      textColor: Colors
                          .white, // Ensure text is readable on the gradient
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
