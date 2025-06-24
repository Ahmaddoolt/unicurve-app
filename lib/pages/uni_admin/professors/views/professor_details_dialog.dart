import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/professor.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/professors/professors_controller.dart';
import 'package:unicurve/pages/uni_admin/professors/views/detail_row.dart';

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
  List<Subject> _teachingSubjects = [];
  bool _isLoading = false;
  String? _majorName;
  bool _hasFetchedData = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_hasFetchedData) return;

    setState(() => _isLoading = true);
    try {
      final controller = ref.read(
        professorsControllerProvider(widget.majorId).notifier,
      );
      _majorName = await controller.supabaseService.fetchMajorName(
        widget.professor.majorId,
      );
      final details = await controller.fetchProfessorDetails(widget.professor);

      _canTeachSubjects =
          (details['canTeachSubjects'] as List<Subject>)
              .where(
                (subject) =>
                    subject.isOpen ||
                    _teachingSubjects.any((s) => s.id == subject.id),
              )
              .toList();
      _teachingSubjects =
          (details['teachingSubjects'] as List<Subject>)
              .where((subject) => subject.isOpen)
              .toList();

      _hasFetchedData = true;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ref
          .read(professorsControllerProvider(widget.majorId).notifier)
          .showSnackBar(
            'prof_error_fetch_details'.trParams({'error': e.toString()}),
            isError: true,
            // ignore: use_build_context_synchronously
            context: context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      backgroundColor: darkerColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: scaleConfig.scale(320),
          maxHeight: scaleConfig.scale(400),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(scaleConfig.scale(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.professor.name ?? 'prof_details_unknown_prof'.tr,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: scaleConfig.scaleText(18),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: scaleConfig.scale(12)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DetailRow(
                            label: 'prof_details_major_label'.tr,
                            value: _majorName ?? 'not_available'.tr,
                            scaleConfig: scaleConfig,
                          ),
                          SizedBox(height: scaleConfig.scale(12)),
                          Text(
                            'prof_details_can_teach_title'.tr,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                          _canTeachSubjects.isEmpty
                              ? Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: scaleConfig.scale(8),
                                ),
                                child: Text(
                                  'prof_details_no_subjects_available'.tr,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: scaleConfig.scaleText(14),
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    _canTeachSubjects.map((subject) {
                                      final isTeaching = _teachingSubjects.any(
                                        (s) => s.id == subject.id,
                                      );
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: scaleConfig.scale(4),
                                        ),
                                        child: Text(
                                          'prof_details_subject_info'.trParams({
                                                'code': subject.code,
                                                'name': subject.name,
                                                'hours':
                                                    subject.hours.toString(),
                                                'level':
                                                    subject.level.toString(),
                                              }) +
                                              (isTeaching
                                                  ? ' - ${'prof_details_teaching_status'.tr}'
                                                  : subject.isOpen
                                                  ? ''
                                                  : ' - ${'prof_dialog_subject_not_open'.tr}'),
                                          style: TextStyle(
                                            color:
                                                isTeaching
                                                    ? AppColors.primary
                                                    : subject.isOpen
                                                    ? AppColors.accent
                                                    : Colors.orange,
                                            fontSize: scaleConfig.scaleText(12),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                          SizedBox(height: scaleConfig.scale(11)),
                          Text(
                            'prof_details_currently_teaching_title'.tr,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                          _teachingSubjects.isEmpty
                              ? Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: scaleConfig.scale(8),
                                ),
                                child: Text(
                                  'prof_details_not_teaching'.tr,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: scaleConfig.scaleText(14),
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    _teachingSubjects.map((subject) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: scaleConfig.scale(4),
                                        ),
                                        child: Text(
                                          'prof_details_subject_info'.trParams({
                                            'code': subject.code,
                                            'name': subject.name,
                                            'hours': subject.hours.toString(),
                                            'level': subject.level.toString(),
                                          }),
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: scaleConfig.scaleText(12),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(12)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'close_button'.tr,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: scaleConfig.scaleText(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: darkerColor,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
