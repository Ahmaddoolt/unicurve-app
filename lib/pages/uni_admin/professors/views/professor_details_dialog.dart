import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  _ProfessorDetailsDialogState createState() => _ProfessorDetailsDialogState();
}

class _ProfessorDetailsDialogState extends ConsumerState<ProfessorDetailsDialog> {
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
      final controller = ref.read(professorsControllerProvider(widget.majorId).notifier);
      _majorName = await controller.supabaseService.fetchMajorName(widget.professor.majorId);
      final details = await controller.fetchProfessorDetails(widget.professor);

      _canTeachSubjects = (details['canTeachSubjects'] as List<Subject>)
          .where((subject) => subject.isOpen || _teachingSubjects.any((s) => s.id == subject.id))
          .toList();
      _teachingSubjects = (details['teachingSubjects'] as List<Subject>).where((subject) => subject.isOpen).toList();

      _hasFetchedData = true;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ref.read(professorsControllerProvider(widget.majorId).notifier).showSnackBar(
            'Error fetching details: $e',
            isError: true,
            context: context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
        side: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      backgroundColor: AppColors.darkBackground,
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
                    widget.professor.name ?? 'Unknown Professor',
                    style: TextStyle(
                      color: AppColors.darkTextPrimary,
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
                            label: 'Major',
                            value: _majorName ?? 'N/A',
                            scaleConfig: scaleConfig,
                          ),
                          SizedBox(height: scaleConfig.scale(12)),
                          Text(
                            'Subjects Can Teach:',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                          _canTeachSubjects.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
                                  child: Text(
                                    'No subjects available',
                                    style: TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: scaleConfig.scaleText(14),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _canTeachSubjects.map((subject) {
                                    final isTeaching = _teachingSubjects.any((s) => s.id == subject.id);
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                                      child: Text(
                                        '${subject.code} - ${subject.name} (Hours: ${subject.hours}, Level: ${subject.level})${isTeaching ? ' - Teaching' : subject.isOpen ? '' : ' - Not Open'}',
                                        style: TextStyle(
                                          color: isTeaching
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
                            'Currently Teaching:',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: scaleConfig.scaleText(14),
                            ),
                          ),
                          _teachingSubjects.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
                                  child: Text(
                                    'Not teaching any subjects',
                                    style: TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: scaleConfig.scaleText(14),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _teachingSubjects.map((subject) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                                      child: Text(
                                        '${subject.code} - ${subject.name} (Hours: ${subject.hours}, Level: ${subject.level})',
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
                        'Close',
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
                color: Colors.black54,
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