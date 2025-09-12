import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';

class SubjectsList extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final Subject? selectedSubject;
  final bool isLoading;
  final Function(Map<String, dynamic>) onSubjectTap;
  final Function(Map<String, dynamic>) onEditSubject;
  final Function(int) onDeleteSubject;

  const SubjectsList({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.isLoading,
    required this.onSubjectTap,
    required this.onEditSubject,
    required this.onDeleteSubject,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      color: lighterColor,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(scaleConfig.scale(16)),
            child: Text(
              'subjects_list_title'.tr,
              style: TextStyle(
                fontSize: scaleConfig.scaleText(14),
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(8)),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final isSelected = selectedSubject?.id == subject['id'];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(4)),
                  child: Card(
                    elevation: isSelected ? 8 : 4,
                    color:
                        isSelected
                            // ignore: deprecated_member_use
                            ? AppColors.primary.withOpacity(0.2)
                            : lighterColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        scaleConfig.scale(12),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: ListTile(
                      minVerticalPadding: scaleConfig.scale(12),
                      title: Text(
                        subject['name'],
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: scaleConfig.scaleText(12),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        'hours_label'.trParams({
                          'hours': '${subject['hours'] ?? 0}',
                        }),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: scaleConfig.scaleText(10),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onTap: () => onSubjectTap(subject),
                      onLongPress: isLoading ? null : () {},

                      // trailing: PopupMenuButton<String>(
                      //   icon: Icon(
                      //     Icons.more_vert,
                      //     color: secondaryTextColor,
                      //     size: scaleConfig.scale(17),
                      //   ),
                      //   onSelected: (value) {
                      //     if (value == 'update') {
                      //       onEditSubject(subject);
                      //     } else if (value == 'delete') {
                      //       showDialog(
                      //         context: context,
                      //         builder:
                      //             (context) => AlertDialog(
                      //               backgroundColor: lighterColor,
                      //               title: Text(
                      //                 'delete_subject_title'.tr,
                      //                 style: TextStyle(
                      //                   color: primaryTextColor,
                      //                   fontSize: scaleConfig.scaleText(15),
                      //                 ),
                      //               ),
                      //               content: Text(
                      //                 'delete_subject_confirm'.trParams({
                      //                   'name': subject['name'],
                      //                 }),
                      //                 style: TextStyle(
                      //                   color: secondaryTextColor,
                      //                   fontSize: scaleConfig.scaleText(14),
                      //                 ),
                      //               ),
                      //               actions: [
                      //                 TextButton(
                      //                   onPressed: () => Navigator.pop(context),
                      //                   child: Text(
                      //                     'cancel'.tr,
                      //                     style: TextStyle(
                      //                       color: AppColors.accent,
                      //                       fontSize: scaleConfig.scaleText(13),
                      //                     ),
                      //                   ),
                      //                 ),
                      //                 TextButton(
                      //                   onPressed: () {
                      //                     Navigator.pop(context);
                      //                     onDeleteSubject(subject['id']);
                      //                   },
                      //                   child: Text(
                      //                     'delete_button'.tr,
                      //                     style: TextStyle(
                      //                       color: AppColors.error,
                      //                       fontSize: scaleConfig.scaleText(13),
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //       );
                      //     }
                      //   },
                      //   itemBuilder:
                      //       (context) => [
                      //         PopupMenuItem(
                      //           value: 'update',
                      //           child: Row(
                      //             children: [
                      //               Icon(
                      //                 Icons.edit,
                      //                 color: AppColors.accent,
                      //                 size: scaleConfig.scale(18),
                      //               ),
                      //               SizedBox(width: scaleConfig.scale(8)),
                      //               Text(
                      //                 'popup_update'.tr,
                      //                 style: TextStyle(
                      //                   color: primaryTextColor,
                      //                   fontSize: scaleConfig.scaleText(14),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //         PopupMenuItem(
                      //           value: 'delete',
                      //           child: Row(
                      //             children: [
                      //               Icon(
                      //                 Icons.delete,
                      //                 color: AppColors.error,
                      //                 size: scaleConfig.scale(18),
                      //               ),
                      //               SizedBox(width: scaleConfig.scale(8)),
                      //               Text(
                      //                 'popup_delete'.tr,
                      //                 style: TextStyle(
                      //                   color: primaryTextColor,
                      //                   fontSize: scaleConfig.scaleText(14),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ],
                      //   enabled: !isLoading,
                      //   color: lighterColor,
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(
                      //       scaleConfig.scale(8),
                      //     ),
                      //   ),
                      // ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
