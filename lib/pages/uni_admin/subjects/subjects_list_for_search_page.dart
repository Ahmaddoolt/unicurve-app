import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class SubjectsListBuilder extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final Function(Map<String, dynamic>) onSubjectTap;
  final Function(Map<String, dynamic>) onEditSubject;
  final Function(Map<String, dynamic>) onDeleteSubject;

  const SubjectsListBuilder({
    super.key,
    required this.subjects,
    required this.onSubjectTap,
    required this.onEditSubject,
    required this.onDeleteSubject,
  });

  void _showMenuForSubject(BuildContext context, Map<String, dynamic> subject) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final scaleConfig = context.scaleConfig;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    showMenu<String>(
      context: context,
      color: lighterColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
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
                'popup_update'.tr,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: scaleConfig.scaleText(14),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
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
                'popup_delete'.tr,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: scaleConfig.scaleText(14),
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((selectedValue) {
      if (selectedValue == null) return;
      if (selectedValue == 'update') {
        onEditSubject(subject);
      } else if (selectedValue == 'delete') {
        onDeleteSubject(subject);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return subjects.isEmpty
        ? Center(
          child: Text(
            'subjects_list_no_subjects_found'.tr,
            style: TextStyle(
              color: secondaryTextColor,
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
                color: darkerColor,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
                ),
                child: ListTile(
                  minVerticalPadding: scaleConfig.scale(12),
                  title: Text(
                    subject['name'],
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: scaleConfig.scaleText(16),
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
                      fontSize: scaleConfig.scaleText(14),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onTap: () => onSubjectTap(subject),
                  trailing: Builder(
                    builder: (menuContext) {
                      return IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.accent,
                          size: scaleConfig.scale(20),
                        ),
                        onPressed: () {
                          _showMenuForSubject(menuContext, subject);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
  }
}
