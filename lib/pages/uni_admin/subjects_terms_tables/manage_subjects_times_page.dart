import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/selected_major_provider.dart';
import 'subjects_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final majorRequirementsMapProvider = FutureProvider.autoDispose
    .family<Map<int, String>, int>((ref, majorId) async {
      final response = await Supabase.instance.client
          .from('major_requirements')
          .select('id, requirement_name')
          .eq('major_id', majorId);

      final Map<int, String> requirementsMap = {
        for (var req in response)
          (req['id'] as int): req['requirement_name'] as String,
      };
      return requirementsMap;
    });

class ManageSubjectsPage extends ConsumerWidget {
  const ManageSubjectsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMajorId = ref.watch(selectedMajorIdProvider);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        backgroundColor: darkerColor,
        centerTitle: true,
        title: Text(
          selectedMajorId == null
              ? 'manage_subjects_select_major_title'.tr
              : 'manage_subjects_title'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (selectedMajorId != null)
            IconButton(
              icon: const Icon(Icons.sync_alt, color: AppColors.accent),
              tooltip: 'manage_subjects_change_major_tooltip'.tr,
              onPressed:
                  () => ref.read(selectedMajorIdProvider.notifier).state = null,
            ),
        ],
      ),
      body:
          selectedMajorId == null
              ? const _MajorSelectorView()
              : _SubjectsListView(majorId: selectedMajorId),
    );
  }
}

class _MajorSelectorView extends ConsumerWidget {
  const _MajorSelectorView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final adminUniversityAsync = ref.watch(adminUniversityProvider);

    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return adminUniversityAsync.when(
      data: (adminUniversity) {
        if (adminUniversity == null) {
          return Center(child: Text('error_admin_uni_not_found'.tr));
        }
        final universityId = adminUniversity['university_id'] as int;
        final majorsAsync = ref.watch(majorsProvider(universityId));
        return majorsAsync.when(
          data: (majors) {
            if (majors.isEmpty) {
              return Center(child: Text('error_no_majors_found'.tr));
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(majorsProvider(universityId).future),
              child: ListView.builder(
                padding: EdgeInsets.all(scaleConfig.scale(16)),
                itemCount: majors.length,
                itemBuilder: (context, index) {
                  final major = majors[index];
                  return Card(
                    elevation: 2,
                    color: darkerColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    margin: EdgeInsets.symmetric(
                      vertical: scaleConfig.scale(6),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: scaleConfig.scale(16),
                        vertical: scaleConfig.scale(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: lighterColor,
                        child: const Icon(
                          Icons.school,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        major.name,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.accent,
                      ),
                      onTap:
                          () =>
                              ref.read(selectedMajorIdProvider.notifier).state =
                                  major.id,
                    ),
                  );
                },
              ),
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          error:
              (e, _) => Center(
                child: Text(
                  'error_loading_majors_generic'.trParams({
                    'error': e.toString(),
                  }),
                ),
              ),
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
      error:
          (e, _) => Center(
            child: Text(
              'error_loading_uni_info_generic'.trParams({
                'error': e.toString(),
              }),
            ),
          ),
    );
  }
}

class _SubjectsListView extends ConsumerStatefulWidget {
  final int majorId;
  const _SubjectsListView({required this.majorId});
  @override
  ConsumerState<_SubjectsListView> createState() => _SubjectsListViewState();
}

class _SubjectsListViewState extends ConsumerState<_SubjectsListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    final subjectsAsync = ref.watch(subjectsProvider(widget.majorId));
    final requirementsMapAsync = ref.watch(
      majorRequirementsMapProvider(widget.majorId),
    );
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(scaleConfig.scale(12)),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: primaryTextColor),
            decoration: InputDecoration(
              hintText: 'manage_subjects_search_hint'.tr,
              hintStyle: TextStyle(color: secondaryTextColor),
              prefixIcon: Icon(Icons.search, color: secondaryTextColor),
              filled: true,
              fillColor: darkerColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
                borderSide: BorderSide.none,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: secondaryTextColor),
                        onPressed: () => _searchController.clear(),
                      )
                      : null,
            ),
          ),
        ),
        Expanded(
          child: requirementsMapAsync.when(
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            error:
                (e, _) => Center(
                  child: Text(
                    'error_loading_requirements_generic'.trParams({
                      'error': e.toString(),
                    }),
                  ),
                ),
            data: (requirementsMap) {
              return subjectsAsync.when(
                data: (subjects) {
                  final filteredSubjects =
                      subjects.where((s) {
                        final typeName = requirementsMap[s.type] ?? '';
                        final query = _searchQuery.toLowerCase();
                        return s.name.toLowerCase().contains(query) ||
                            s.code.toLowerCase().contains(query) ||
                            typeName.toLowerCase().contains(query);
                      }).toList();

                  if (filteredSubjects.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'manage_subjects_no_match_search'.tr
                            : 'manage_subjects_no_subjects_found'.tr,
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(subjectsProvider(widget.majorId));
                      ref.invalidate(
                        majorRequirementsMapProvider(widget.majorId),
                      );
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: scaleConfig.scale(8),
                      ),
                      itemCount: filteredSubjects.length,
                      itemBuilder:
                          (context, index) => _SubjectCard(
                            subject: filteredSubjects[index],
                            requirementsMap: requirementsMap,
                          ),
                    ),
                  );
                },
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                error:
                    (e, _) => Center(
                      child: Text(
                        'error_generic'.trParams({'error': e.toString()}),
                      ),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends ConsumerStatefulWidget {
  final Subject subject;
  final Map<int, String> requirementsMap;
  const _SubjectCard({required this.subject, required this.requirementsMap});
  @override
  ConsumerState<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends ConsumerState<_SubjectCard> {
  bool _isStatusLoading = false;

  @override
  Widget build(BuildContext context) {
    final scaleConfig = ScaleConfig(context);
    final groupsAsync = ref.watch(subjectGroupsProvider(widget.subject.id!));
    final String typeName =
        widget.requirementsMap[widget.subject.type] ?? 'uncategorized_label'.tr;
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: darkerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          fontSize: scaleConfig.scale(16),
                        ),
                      ),
                      SizedBox(height: scaleConfig.scale(4)),
                      Text(
                        widget.subject.code,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: scaleConfig.scale(12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isStatusLoading)
                  const SizedBox(
                    height: 30,
                    width: 30,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Switch(
                    value: widget.subject.isOpen,
                    onChanged: (newValue) async {
                      setState(() => _isStatusLoading = true);
                      try {
                        await ref
                            .read(subjectsRepositoryProvider)
                            .updateSubjectStatus(widget.subject.id!, newValue);
                        ref.invalidate(
                          subjectsProvider(widget.subject.majorId!),
                        );
                      } finally {
                        if (mounted) setState(() => _isStatusLoading = false);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
              ],
            ),
            SizedBox(height: scaleConfig.scale(12)),
            Wrap(
              spacing: scaleConfig.scale(8),
              runSpacing: scaleConfig.scale(4),
              children: [
                Chip(
                  label: Text(
                    'chip_level'.trParams({
                      'level': widget.subject.level.toString(),
                    }),
                  ),
                  // ignore: deprecated_member_use
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: const TextStyle(color: AppColors.primary),
                ),
                Chip(
                  label: Text(
                    'chip_hours'.trParams({
                      'hours': widget.subject.hours.toString(),
                    }),
                  ),
                  // ignore: deprecated_member_use
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  labelStyle: const TextStyle(color: AppColors.accent),
                ),
                Chip(
                  label: Text(typeName),
                  // ignore: deprecated_member_use
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.teal),
                ),
              ],
            ),
            Divider(height: 32, color: lighterColor),
            Opacity(
              opacity: widget.subject.isOpen ? 1.0 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'groups_title'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: scaleConfig.scale(14),
                      color: primaryTextColor,
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(12)),
                  groupsAsync.when(
                    data:
                        (groups) => Column(
                          children: [
                            if (groups.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Text(
                                  'groups_none_available'.tr,
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              ),
                            ...groups.map((group) => _GroupItem(group: group)),
                            SizedBox(height: scaleConfig.scale(12)),
                            if (widget.subject.isOpen)
                              Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  onPressed:
                                      () => showDialog(
                                        context: context,
                                        builder:
                                            (_) => _AddScheduleDialog(
                                              subjectId: widget.subject.id!,
                                            ),
                                      ),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    'groups_add_button'.tr,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    error:
                        (e, _) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'error_generic'.trParams({'error': e.toString()}),
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupItem extends ConsumerWidget {
  final SubjectGroup group;
  const _GroupItem({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final theoretical = group.schedules.where(
      (s) => s.scheduleType == 'THEORETICAL',
    );
    final practical = group.schedules.where(
      (s) => s.scheduleType == 'PRACTICAL',
    );
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: EdgeInsets.all(scaleConfig.scale(12)),
      margin: EdgeInsets.only(bottom: scaleConfig.scale(8)),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: lighterColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'group_code_label'.trParams({'code': group.groupCode}),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: scaleConfig.scale(14),
                ),
              ),
              IconButton(
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                onPressed:
                    () => showDialog(
                      context: context,
                      builder:
                          (_) => _DeleteGroupConfirmationDialog(group: group),
                    ),
              ),
            ],
          ),
          Divider(color: darkerColor, height: 16),
          if (theoretical.isNotEmpty) ...[
            Text(
              'group_theoretical_label'.tr,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            ...theoretical.map(
              (s) => ScheduleRow(schedule: s, subjectId: group.subjectId),
            ),
          ],
          if (practical.isNotEmpty) ...[
            SizedBox(height: theoretical.isNotEmpty ? 8 : 0),
            Text(
              'group_practical_label'.tr,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            ...practical.map(
              (s) => ScheduleRow(schedule: s, subjectId: group.subjectId),
            ),
          ],
        ],
      ),
    );
  }
}

class ScheduleRow extends ConsumerWidget {
  final Schedule schedule;
  final int subjectId;
  const ScheduleRow({
    super.key,
    required this.schedule,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${schedule.dayOfWeek.tr}: ${schedule.startTime} - ${schedule.endTime}',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          IconButton(
            iconSize: 18,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(Icons.edit, color: AppColors.accent),
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (_) => _EditScheduleDialog(
                        schedule: schedule,
                        subjectId: subjectId,
                      ),
                ),
          ),
          IconButton(
            iconSize: 18,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: lighterColor,
                    title: Text(
                      'delete_schedule_title'.tr,
                      style: TextStyle(color: primaryTextColor),
                    ),
                    content: Text(
                      'delete_schedule_confirm'.trParams({
                        'type':
                            schedule.scheduleType == 'THEORETICAL'
                                ? 'schedule_type_theoretical'.tr
                                : 'schedule_type_practical'.tr,
                      }),
                      style: TextStyle(color: secondaryTextColor),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'cancel'.tr,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ),
                      TextButton(
                        child: Text(
                          'delete_button'.tr,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        onPressed: () async {
                          await ref
                              .read(subjectsRepositoryProvider)
                              .deleteSchedule(schedule.id);
                          // ignore: unused_result
                          ref.refresh(subjectGroupsProvider(subjectId).future);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeleteGroupConfirmationDialog extends ConsumerStatefulWidget {
  final SubjectGroup group;
  const _DeleteGroupConfirmationDialog({required this.group});
  @override
  ConsumerState<_DeleteGroupConfirmationDialog> createState() =>
      _DeleteGroupConfirmationDialogState();
}

class _DeleteGroupConfirmationDialogState
    extends ConsumerState<_DeleteGroupConfirmationDialog> {
  bool _isDeleting = false;
  @override
  Widget build(BuildContext context) {
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return AlertDialog(
      backgroundColor: lighterColor,
      title: Text(
        'delete_group_title'.tr,
        style: TextStyle(color: primaryTextColor),
      ),
      content: Text(
        'delete_group_confirm'.trParams({'code': widget.group.groupCode}),
        style: TextStyle(color: secondaryTextColor),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr, style: TextStyle(color: secondaryTextColor)),
        ),
        TextButton(
          onPressed:
              _isDeleting
                  ? null
                  : () async {
                    setState(() => _isDeleting = true);
                    try {
                      await ref
                          .read(subjectsRepositoryProvider)
                          .deleteGroup(widget.group.id);
                      // ignore: unused_result
                      ref.refresh(
                        subjectGroupsProvider(widget.group.subjectId).future,
                      );
                      // ignore: use_build_context_synchronously
                      if (mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                        showFeedbackSnackbar(
                          // ignore: use_build_context_synchronously
                          context,
                          'error_delete_failed'.tr,
                          isError: true,
                        );
                      }
                    }
                  },
          child:
              _isDeleting
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                  : Text(
                    'delete_button'.tr,
                    style: const TextStyle(color: AppColors.error),
                  ),
        ),
      ],
    );
  }
}

class _AddScheduleDialog extends ConsumerStatefulWidget {
  final int subjectId;
  const _AddScheduleDialog({required this.subjectId});
  @override
  ConsumerState<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends ConsumerState<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupCodeController = TextEditingController();
  String? _selectedDay, _selectedType;
  TimeOfDay? _startTime, _endTime;
  bool _isLoading = false;

  final _days = [
    'day_sunday',
    'day_monday',
    'day_tuesday',
    'day_wednesday',
    'day_thursday',
    'day_friday',
    'day_saturday',
  ];

  final _types = ['schedule_type_theoretical', 'schedule_type_practical'];

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder:
          (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Theme.of(context).textTheme.bodyLarge!.color!,
                surface: Theme.of(context).scaffoldBackgroundColor,
                onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              // ignore: deprecated_member_use
              dialogBackgroundColor: Theme.of(context).cardColor,
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      showFeedbackSnackbar(context, 'error_select_times'.tr, isError: true);
      return;
    }
    if (_startTime!.hour > _endTime!.hour ||
        (_startTime!.hour == _endTime!.hour &&
            _startTime!.minute >= _endTime!.minute)) {
      showFeedbackSnackbar(
        context,
        'error_end_time_after_start'.tr,
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    final startTimeStr =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr =
        '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
    final groupCode = _groupCodeController.text.trim();
    try {
      final conflict = await ref
          .read(subjectsRepositoryProvider)
          .checkGroupConflict(
            subjectId: widget.subjectId,
            groupCode: groupCode,
            scheduleType:
                _selectedType == 'schedule_type_theoretical'
                    ? 'THEORETICAL'
                    : 'PRACTICAL',
            dayOfWeek:
                _selectedDay == 'day_sunday'
                    ? 'Sunday'
                    : _selectedDay == 'day_monday'
                    ? 'Monday'
                    : _selectedDay == 'day_tuesday'
                    ? 'Tuesday'
                    : _selectedDay == 'day_wednesday'
                    ? 'Wednesday'
                    : _selectedDay == 'day_thursday'
                    ? 'Thursday'
                    : _selectedDay == 'day_friday'
                    ? 'Friday'
                    : 'Saturday',
            startTime: startTimeStr,
            endTime: endTimeStr,
          );
      if (conflict != null) {
        if (mounted) showFeedbackSnackbar(context, conflict, isError: true);
        setState(() => _isLoading = false);
        return;
      }
      await ref
          .read(subjectsRepositoryProvider)
          .addGroupWithSchedule(
            subjectId: widget.subjectId,
            groupCode: groupCode,
            dayOfWeek:
                _selectedDay == 'day_sunday'
                    ? 'Sunday'
                    : _selectedDay == 'day_monday'
                    ? 'Monday'
                    : _selectedDay == 'day_tuesday'
                    ? 'Tuesday'
                    : _selectedDay == 'day_wednesday'
                    ? 'Wednesday'
                    : _selectedDay == 'day_thursday'
                    ? 'Thursday'
                    : _selectedDay == 'day_friday'
                    ? 'Friday'
                    : 'Saturday',
            startTime: startTimeStr,
            endTime: endTimeStr,
            scheduleType:
                _selectedType == 'schedule_type_theoretical'
                    ? 'THEORETICAL'
                    : 'PRACTICAL',
          );
      // ignore: unused_result
      ref.refresh(subjectGroupsProvider(widget.subjectId).future);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'error_generic'.trParams({'error': e.toString()}),
          isError: true,
        );
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _groupCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: secondaryTextColor),
      enabledBorder: UnderlineInputBorder(
        // ignore: deprecated_member_use
        borderSide: BorderSide(color: secondaryTextColor!.withOpacity(0.5)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
    return AlertDialog(
      backgroundColor: lighterColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'groups_add_button'.tr,
        style: TextStyle(color: primaryTextColor),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _groupCodeController,
                decoration: inputDecoration.copyWith(
                  labelText: 'group_code_hint'.tr,
                ),
                style: TextStyle(color: primaryTextColor),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'error_field_empty'.tr
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                hint: Text(
                  'select_day_hint'.tr,
                  style: TextStyle(color: secondaryTextColor),
                ),
                onChanged: (v) => setState(() => _selectedDay = v),
                items:
                    _days
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text(d.tr)),
                        )
                        .toList(),
                decoration: inputDecoration,
                dropdownColor: darkerColor,
                style: TextStyle(color: primaryTextColor),
                validator: (v) => v == null ? 'error_please_select'.tr : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: Text(
                  'select_type_hint'.tr,
                  style: TextStyle(color: secondaryTextColor),
                ),
                onChanged: (v) => setState(() => _selectedType = v),
                items:
                    _types
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t.tr)),
                        )
                        .toList(),
                decoration: inputDecoration,
                dropdownColor: darkerColor,
                style: TextStyle(color: primaryTextColor),
                validator: (v) => v == null ? 'error_please_select'.tr : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${'time_start_label'.tr}: ${_startTime?.format(context) ?? 'time_not_set'.tr}',
                  style: TextStyle(color: secondaryTextColor),
                ),
                trailing: const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                ),
                onTap: () => _pickTime(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${'time_end_label'.tr}: ${_endTime?.format(context) ?? 'time_not_set'.tr}',
                  style: TextStyle(color: secondaryTextColor),
                ),
                trailing: const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                ),
                onTap: () => _pickTime(false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr, style: TextStyle(color: secondaryTextColor)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isLoading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryTextColor,
                    ),
                  )
                  : Text(
                    'save_button'.tr,
                    style: TextStyle(color: primaryTextColor),
                  ),
        ),
      ],
    );
  }
}

class _EditScheduleDialog extends ConsumerStatefulWidget {
  final Schedule schedule;
  final int subjectId;
  const _EditScheduleDialog({required this.schedule, required this.subjectId});
  @override
  ConsumerState<_EditScheduleDialog> createState() =>
      _EditScheduleDialogState();
}

class _EditScheduleDialogState extends ConsumerState<_EditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDay;
  TimeOfDay? _startTime, _endTime;
  bool _isLoading = false;

  final _days = [
    'day_sunday',
    'day_monday',
    'day_tuesday',
    'day_wednesday',
    'day_thursday',
    'day_friday',
    'day_saturday',
  ];

  String _dayToKey(String day) {
    return 'day_${day.toLowerCase()}';
  }

  String _keyToDay(String key) {
    return key.split('_')[1].capitalizeFirst ?? key;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _selectedDay = _dayToKey(s.dayOfWeek);
    final start = s.startTime.split(':');
    _startTime = TimeOfDay(
      hour: int.parse(start[0]),
      minute: int.parse(start[1]),
    );
    final end = s.endTime.split(':');
    _endTime = TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1]));
  }

  Future<void> _pickTime(bool isStart) async {
    final initial =
        isStart
            ? (_startTime ?? TimeOfDay.now())
            : (_endTime ?? TimeOfDay.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder:
          (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Theme.of(context).textTheme.bodyLarge!.color!,
                surface: Theme.of(context).scaffoldBackgroundColor,
                onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              // ignore: deprecated_member_use
              dialogBackgroundColor: Theme.of(context).cardColor,
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      showFeedbackSnackbar(context, 'error_select_times'.tr, isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final startTimeStr =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr =
        '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
    try {
      final conflict = await ref
          .read(subjectsRepositoryProvider)
          .checkGroupConflict(
            subjectId: widget.subjectId,
            groupCode: "N/A",
            scheduleType: widget.schedule.scheduleType,
            dayOfWeek: _keyToDay(_selectedDay!),
            startTime: startTimeStr,
            endTime: endTimeStr,
            editingScheduleId: widget.schedule.id,
          );
      if (conflict != null) {
        if (mounted) showFeedbackSnackbar(context, conflict, isError: true);
        setState(() => _isLoading = false);
        return;
      }
      await ref
          .read(subjectsRepositoryProvider)
          .updateSchedule(
            widget.schedule.id,
            dayOfWeek: _keyToDay(_selectedDay!),
            startTime: startTimeStr,
            endTime: endTimeStr,
          );
      // ignore: unused_result
      ref.refresh(subjectGroupsProvider(widget.subjectId).future);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'error_generic'.trParams({'error': e.toString()}),
          isError: true,
        );
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: secondaryTextColor),
      enabledBorder: UnderlineInputBorder(
        // ignore: deprecated_member_use
        borderSide: BorderSide(color: secondaryTextColor!.withOpacity(0.5)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
    return AlertDialog(
      backgroundColor: lighterColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'edit_schedule_title'.tr,
        style: TextStyle(color: primaryTextColor),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDay,
                hint: Text(
                  'select_day_hint'.tr,
                  style: TextStyle(color: secondaryTextColor),
                ),
                onChanged: (v) => setState(() => _selectedDay = v),
                items:
                    _days
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text(d.tr)),
                        )
                        .toList(),
                decoration: inputDecoration,
                dropdownColor: darkerColor,
                style: TextStyle(color: primaryTextColor),
                validator: (v) => v == null ? 'error_please_select'.tr : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${'time_start_label'.tr}: ${_startTime?.format(context) ?? 'time_not_set'.tr}',
                  style: TextStyle(color: secondaryTextColor),
                ),
                trailing: const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                ),
                onTap: () => _pickTime(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${'time_end_label'.tr}: ${_endTime?.format(context) ?? 'time_not_set'.tr}',
                  style: TextStyle(color: secondaryTextColor),
                ),
                trailing: const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                ),
                onTap: () => _pickTime(false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr, style: TextStyle(color: secondaryTextColor)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isLoading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryTextColor,
                    ),
                  )
                  : Text(
                    'update_button'.tr,
                    style: TextStyle(color: primaryTextColor),
                  ),
        ),
      ],
    );
  }
}
