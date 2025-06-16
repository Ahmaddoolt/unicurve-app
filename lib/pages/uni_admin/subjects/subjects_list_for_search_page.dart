import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class SubjectsListBuilder extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final bool isLoading;
  final Function(Map<String, dynamic>) onSubjectTap;
  final Function(Map<String, dynamic>) onEditSubject;
  final Function(int) onDeleteSubject;

  const SubjectsListBuilder({
    super.key,
    required this.subjects,
    required this.isLoading,
    required this.onSubjectTap,
    required this.onEditSubject,
    required this.onDeleteSubject,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;

    return subjects.isEmpty
        ? Center(
            child: Text(
              'No subjects found',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: scaleConfig.scaleText(16),
              ),
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(8)),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                child: Card(
                  elevation: 4,
                  color: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ListTile(
                    minVerticalPadding: scaleConfig.scale(12),
                    title: Text(
                      subject['name'],
                      style: TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: scaleConfig.scaleText(16),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      '${subject['hours'] ?? 0} hr',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: scaleConfig.scaleText(14),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onTap: () => onSubjectTap(subject),
                    onLongPress: isLoading ? null : () {},
                    trailing: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.accent,
                        size: scaleConfig.scale(20),
                      ),
                      onSelected: (value) {
                        if (value == 'update') {
                          onEditSubject(subject);
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.darkSurface,
                              title: Text(
                                'Delete Subject',
                                style: TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: scaleConfig.scaleText(18),
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete ${subject['name']}?',
                                style: TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: scaleConfig.scaleText(16),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: scaleConfig.scaleText(14),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDeleteSubject(subject['id']);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: scaleConfig.scaleText(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'update',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: AppColors.accent,
                                size: scaleConfig.scale(18),
                              ),
                              SizedBox(width: scaleConfig.scale(8)),
                              Text(
                                'Update',
                                style: TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: scaleConfig.scaleText(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color: AppColors.error,
                                size: scaleConfig.scale(18),
                              ),
                              SizedBox(width: scaleConfig.scale(8)),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: scaleConfig.scaleText(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      enabled: !isLoading,
                      color: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}