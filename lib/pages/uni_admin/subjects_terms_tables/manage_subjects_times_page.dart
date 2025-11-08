// lib/pages/uni_admin/subjects_terms_tables/manage_subjects_times_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart'; // --- FIX: Import the overlay ---
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/providers/selected_major_provider.dart';
import 'subjects_repository.dart';

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'manage_subjects_title'.tr,
    );

    final bodyContent = selectedMajorId == null
        ? Center(child: Text('error_no_major_selected'.tr))
        : _SubjectsListView(majorId: selectedMajorId);

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
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
    final requirementsMapAsync =
        ref.watch(majorRequirementsMapProvider(widget.majorId));
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Safely get data or default to empty
    final requirementsMap = requirementsMapAsync.valueOrNull ?? {};
    final subjects = subjectsAsync.valueOrNull ?? [];

    final filteredSubjects = subjects.where((s) {
      final typeName = requirementsMap[s.type] ?? '';
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
          s.code.toLowerCase().contains(query) ||
          typeName.toLowerCase().contains(query);
    }).toList();

    return GlassLoadingOverlay(
      isLoading: (subjectsAsync.isLoading && !subjectsAsync.hasValue) ||
          (requirementsMapAsync.isLoading && !requirementsMapAsync.hasValue),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(scaleConfig.scale(12),
                scaleConfig.scale(12), scaleConfig.scale(12), 0),
            child: isDarkMode
                ? GlassCard(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildSearchField(theme),
                  )
                : _buildSearchField(theme),
          ),
          Expanded(
            child: (subjectsAsync.hasError || requirementsMapAsync.hasError)
                ? Center(
                    child: Text('error_generic'.trParams({
                    'error': (subjectsAsync.error ?? requirementsMapAsync.error)
                        .toString()
                  })))
                : (filteredSubjects.isEmpty && subjects.isNotEmpty)
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'manage_subjects_no_match_search'.tr
                              : 'manage_subjects_no_subjects_found'.tr,
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(subjectsProvider(widget.majorId));
                          ref.invalidate(
                              majorRequirementsMapProvider(widget.majorId));
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.all(scaleConfig.scale(8)),
                          itemCount: filteredSubjects.length,
                          itemBuilder: (context, index) => _SubjectCard(
                            subject: filteredSubjects[index],
                            requirementsMap: requirementsMap,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'manage_subjects_search_hint'.tr,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.transparent
            : theme.inputDecorationTheme.fillColor,
        border: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.border,
        enabledBorder: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.brightness == Brightness.dark
            ? InputBorder.none
            : theme.inputDecorationTheme.focusedBorder,
      ).applyDefaults(theme.inputDecorationTheme).copyWith(
            prefixIcon:
                Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: theme.textTheme.bodyMedium?.color),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
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
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: scaleConfig.scale(16),
                        ),
                      ),
                      SizedBox(height: scaleConfig.scale(4)),
                      Text(
                        widget.subject.code,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: scaleConfig.scale(12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isStatusLoading)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primary),
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
                  label: Text('chip_level'
                      .trParams({'level': widget.subject.level.toString()})),
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('chip_hours'
                      .trParams({'hours': widget.subject.hours.toString()})),
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  labelStyle: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(typeName),
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  labelStyle: const TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 32, color: theme.dividerColor.withOpacity(0.5)),
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
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: scaleConfig.scale(12)),
                  groupsAsync.when(
                    data: (groups) => Column(
                      children: [
                        if (groups.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('groups_none_available'.tr,
                                style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color)),
                          ),
                        ...groups.map((group) => _GroupItem(group: group)),
                        SizedBox(height: scaleConfig.scale(12)),
                        if (widget.subject.isOpen)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => _AddScheduleDialog(
                                      subjectId: widget.subject.id!)),
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.primary),
                              label: Text('groups_add_button'.tr,
                                  style: const TextStyle(
                                      color: AppColors.primary)),
                            ),
                          ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                          'error_generic'.trParams({'error': e.toString()}),
                          style: const TextStyle(color: AppColors.error)),
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
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;

    return GlassCard(
      margin: EdgeInsets.only(bottom: scaleConfig.scale(8)),
      borderRadius: BorderRadius.circular(scaleConfig.scale(8)),
      child: Padding(
        padding: EdgeInsets.all(scaleConfig.scale(12)),
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
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) =>
                        _DeleteGroupConfirmationDialog(group: group),
                  ),
                ),
              ],
            ),
            Divider(color: theme.dividerColor.withOpacity(0.5), height: 16),
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
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

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
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _EditScheduleDialog(
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
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.transparent
                        : theme.cardColor,
                    elevation: 0,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: GlassCard(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 24, left: 24, right: 24, bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'delete_schedule_title'.tr,
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'delete_schedule_confirm'.trParams({
                                'type': schedule.scheduleType == 'THEORETICAL'
                                    ? 'schedule_type_theoretical'.tr
                                    : 'schedule_type_practical'.tr,
                              }),
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
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
                                    style:
                                        const TextStyle(color: AppColors.error),
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(subjectsRepositoryProvider)
                                        .deleteSchedule(schedule.id);
                                    ref.invalidate(
                                        subjectGroupsProvider(subjectId));
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

    return AlertDialog(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.transparent
          : theme.cardColor,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: GlassCard(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'delete_group_title'.tr,
                style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                'delete_group_confirm'
                    .trParams({'code': widget.group.groupCode}),
                style: TextStyle(color: secondaryTextColor),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr,
                        style: TextStyle(color: secondaryTextColor)),
                  ),
                  TextButton(
                    onPressed: _isDeleting
                        ? null
                        : () async {
                            setState(() => _isDeleting = true);
                            try {
                              await ref
                                  .read(subjectsRepositoryProvider)
                                  .deleteGroup(widget.group.id);
                              ref.invalidate(
                                subjectGroupsProvider(widget.group.subjectId),
                              );
                              if (mounted) Navigator.of(context).pop();
                            } catch (e) {
                              if (mounted) {
                                Navigator.of(context).pop();
                                showFeedbackSnackbar(
                                  context,
                                  'error_delete_failed'.tr,
                                  isError: true,
                                );
                              }
                            }
                          },
                    child: _isDeleting
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
              ),
            ],
          ),
        ),
      ),
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
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hourMinuteColor: AppColors.primary,
              hourMinuteTextColor: Colors.white,
              dialBackgroundColor: theme.colorScheme.surface,
              dialHandColor: AppColors.primary,
              dialTextColor: theme.colorScheme.onSurface,
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? AppColors.accent
                      : theme.colorScheme.surface),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? Colors.white
                      : theme.colorScheme.onSurface),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface),
            ),
          ),
          child: child!,
        );
      },
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
      final conflict =
          await ref.read(subjectsRepositoryProvider).checkGroupConflict(
                subjectId: widget.subjectId,
                groupCode: groupCode,
                scheduleType: _selectedType == 'schedule_type_theoretical'
                    ? 'THEORETICAL'
                    : 'PRACTICAL',
                dayOfWeek: _selectedDay == 'day_sunday'
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
      await ref.read(subjectsRepositoryProvider).addGroupWithSchedule(
            subjectId: widget.subjectId,
            groupCode: groupCode,
            dayOfWeek: _selectedDay == 'day_sunday'
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
            scheduleType: _selectedType == 'schedule_type_theoretical'
                ? 'THEORETICAL'
                : 'PRACTICAL',
          );
      ref.invalidate(subjectGroupsProvider(widget.subjectId));
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
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

    final customInputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
    );

    return AlertDialog(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF2D3748)
          : theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'groups_add_button'.tr,
        style: TextStyle(
            color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _groupCodeController,
              decoration: customInputDecoration.copyWith(
                hintText: 'group_code_hint'.tr,
                hintStyle: TextStyle(color: secondaryTextColor),
              ),
              style: TextStyle(color: primaryTextColor, fontSize: 16),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'error_field_empty'.tr : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDay,
              hint: Text(
                'select_day_hint'.tr,
                style: TextStyle(color: secondaryTextColor),
              ),
              onChanged: (v) => setState(() => _selectedDay = v),
              items: _days
                  .map(
                    (d) => DropdownMenuItem(value: d, child: Text(d.tr)),
                  )
                  .toList(),
              decoration: customInputDecoration,
              dropdownColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF2D3748)
                  : theme.cardColor,
              style: TextStyle(color: primaryTextColor, fontSize: 16),
              icon: Icon(Icons.keyboard_arrow_down, color: primaryTextColor),
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
              items: _types
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.tr)),
                  )
                  .toList(),
              decoration: customInputDecoration,
              dropdownColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF2D3748)
                  : theme.cardColor,
              style: TextStyle(color: primaryTextColor, fontSize: 16),
              icon: Icon(Icons.keyboard_arrow_down, color: primaryTextColor),
              validator: (v) => v == null ? 'error_please_select'.tr : null,
            ),
            const SizedBox(height: 24),
            _buildTimePickerRow(
              context: context,
              label: 'time_start_label'.tr,
              timeOfDay: _startTime,
              onTap: () => _pickTime(true),
            ),
            const SizedBox(height: 16),
            _buildTimePickerRow(
              context: context,
              label: 'time_end_label'.tr,
              timeOfDay: _endTime,
              onTap: () => _pickTime(false),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('cancel'.tr, style: TextStyle(color: secondaryTextColor)),
        ),
        // --- THE FIX IS HERE ---
        // Replaced ElevatedButton with our consistent, gradient-enabled CustomButton
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          )
        else
          CustomButton(
            onPressed: _submitForm,
            text: 'save_button'.tr,
            gradient: AppColors.primaryGradient,
          ),
      ],
    );
  }

  Widget _buildTimePickerRow({
    required BuildContext context,
    required String label,
    required TimeOfDay? timeOfDay,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final formattedTime = timeOfDay?.format(context) ?? 'time_not_set'.tr;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
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
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hourMinuteColor: AppColors.primary,
              hourMinuteTextColor: Colors.white,
              dialBackgroundColor: theme.colorScheme.surface,
              dialHandColor: AppColors.primary,
              dialTextColor: theme.colorScheme.onSurface,
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? AppColors.accent
                      : theme.colorScheme.surface),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? Colors.white
                      : theme.colorScheme.onSurface),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface),
            ),
          ),
          child: child!,
        );
      },
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
      final conflict =
          await ref.read(subjectsRepositoryProvider).checkGroupConflict(
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
      await ref.read(subjectsRepositoryProvider).updateSchedule(
            widget.schedule.id,
            dayOfWeek: _keyToDay(_selectedDay!),
            startTime: startTimeStr,
            endTime: endTimeStr,
          );
      ref.invalidate(subjectGroupsProvider(widget.subjectId));
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
    final theme = Theme.of(context);
    Color? primaryTextColor = theme.textTheme.bodyLarge?.color;
    Color? secondaryTextColor = theme.textTheme.bodyMedium?.color;

    return AlertDialog(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF2D3748)
          : theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'edit_schedule_title'.tr,
        style: TextStyle(
            color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDay,
              hint: Text(
                'select_day_hint'.tr,
                style: TextStyle(color: secondaryTextColor),
              ),
              onChanged: (v) => setState(() => _selectedDay = v),
              items: _days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.tr)))
                  .toList(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 15.0),
              ),
              dropdownColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF2D3748)
                  : theme.cardColor,
              style: TextStyle(color: primaryTextColor, fontSize: 16),
              icon: Icon(Icons.keyboard_arrow_down, color: primaryTextColor),
              validator: (v) => v == null ? 'error_please_select'.tr : null,
            ),
            const SizedBox(height: 24),
            _buildTimePickerRow(
              context: context,
              label: 'time_start_label'.tr,
              timeOfDay: _startTime,
              onTap: () => _pickTime(true),
            ),
            const SizedBox(height: 16),
            _buildTimePickerRow(
              context: context,
              label: 'time_end_label'.tr,
              timeOfDay: _endTime,
              onTap: () => _pickTime(false),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('cancel'.tr, style: TextStyle(color: secondaryTextColor)),
        ),
        // --- THE FIX IS HERE ---
        // Replaced ElevatedButton with our consistent, reusable CustomButton.
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          )
        else
          CustomButton(
            onPressed: _submitForm,
            text: 'update_button'.tr,
            gradient: AppColors.primaryGradient,
          ),
      ],
    );
  }

  Widget _buildTimePickerRow({
    required BuildContext context,
    required String label,
    required TimeOfDay? timeOfDay,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final formattedTime = timeOfDay?.format(context) ?? 'time_not_set'.tr;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
