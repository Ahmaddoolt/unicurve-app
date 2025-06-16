// lib/pages/uni_admin/manage_subjects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/subject.dart';
import 'package:unicurve/pages/uni_admin/providers/admin_university_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/majors_provider.dart';
import 'package:unicurve/pages/uni_admin/providers/selected_major_provider.dart';
import 'subjects_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// --- NEW PROVIDER: To fetch requirement names for the selected major ---
final majorRequirementsMapProvider =
    FutureProvider.autoDispose.family<Map<int, String>, int>((ref, majorId) async {
  final response = await Supabase.instance.client
      .from('major_requirements')
      .select('id, requirement_name')
      .eq('major_id', majorId);

  final Map<int, String> requirementsMap = {
    for (var req in response) (req['id'] as int): req['requirement_name'] as String
  };
  return requirementsMap;
});

// --- MAIN PAGE and MAJOR SELECTOR WIDGETS ---
class ManageSubjectsPage extends ConsumerWidget {
  const ManageSubjectsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMajorId = ref.watch(selectedMajorIdProvider);
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground, centerTitle: true,
        title: Text( selectedMajorId == null ? 'Select a Major' : 'Manage Subjects', style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
        actions: [ if (selectedMajorId != null) IconButton(icon: const Icon(Icons.sync_alt, color: AppColors.accent), tooltip: 'Change Major', onPressed: () => ref.read(selectedMajorIdProvider.notifier).state = null) ],
      ),
      body: selectedMajorId == null ? const _MajorSelectorView() : _SubjectsListView(majorId: selectedMajorId),
    );
  }
}
class _MajorSelectorView extends ConsumerWidget {
  const _MajorSelectorView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final adminUniversityAsync = ref.watch(adminUniversityProvider);
    return adminUniversityAsync.when(
      data: (adminUniversity) {
        if (adminUniversity == null) return const Center(child: Text('Admin university not found.'));
        final universityId = adminUniversity['university_id'] as int;
        final majorsAsync = ref.watch(majorsProvider(universityId));
        return majorsAsync.when(
          data: (majors) {
            if (majors.isEmpty) return const Center(child: Text('No majors found for your university.'));
            return RefreshIndicator(
              onRefresh: () => ref.refresh(majorsProvider(universityId).future),
              child: ListView.builder(
                padding: EdgeInsets.all(scaleConfig.scale(16)), itemCount: majors.length,
                itemBuilder: (context, index) {
                  final major = majors[index];
                  return Card(
                    elevation: 2, color: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(8)), side: const BorderSide(color: AppColors.primary, width: 1.5)),
                    margin: EdgeInsets.symmetric(vertical: scaleConfig.scale(6)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(16), vertical: scaleConfig.scale(12)),
                      leading: const CircleAvatar(backgroundColor: AppColors.darkSurface, child: Icon(Icons.school, color: AppColors.primary)),
                      title: Text(major.name, style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.accent),
                      onTap: () => ref.read(selectedMajorIdProvider.notifier).state = major.id,
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error loading majors: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error loading university info: $e')),
    );
  }
}

// --- SUBJECTS LIST VIEW (UPDATED) ---
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
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
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
    final requirementsMapAsync = ref.watch(majorRequirementsMapProvider(widget.majorId));

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(scaleConfig.scale(12)),
          child: TextField(
            controller: _searchController, style: const TextStyle(color: AppColors.darkTextPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, code, or type...', hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.darkTextSecondary), filled: true, fillColor: AppColors.darkBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(8)), borderSide: BorderSide.none),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppColors.darkTextSecondary), onPressed: () => _searchController.clear()) : null,
            ),
          ),
        ),
        Expanded(
          child: requirementsMapAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error loading requirements: $e')),
            data: (requirementsMap) {
              return subjectsAsync.when(
                data: (subjects) {
                  final filteredSubjects = subjects.where((s) {
                    final typeName = requirementsMap[s.type] ?? '';
                    final query = _searchQuery.toLowerCase();
                    return s.name.toLowerCase().contains(query) || 
                           s.code.toLowerCase().contains(query) ||
                           typeName.toLowerCase().contains(query);
                  }).toList();

                  if (filteredSubjects.isEmpty) return Center(child: Text(_searchQuery.isNotEmpty ? 'No subjects match your search.' : 'No subjects found for this major.', style: const TextStyle(color: AppColors.darkTextSecondary)));
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(subjectsProvider(widget.majorId));
                      ref.invalidate(majorRequirementsMapProvider(widget.majorId));
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(8)), itemCount: filteredSubjects.length,
                      itemBuilder: (context, index) => _SubjectCard(subject: filteredSubjects[index], requirementsMap: requirementsMap),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
            },
          )
        ),
      ],
    );
  }
}

// --- SUBJECT CARD (UPDATED) ---
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
    final String typeName = widget.requirementsMap[widget.subject.type] ?? 'Uncategorized';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), color: AppColors.darkBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleConfig.scale(12))), elevation: 2,
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
                      Text(widget.subject.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary, fontSize: scaleConfig.scale(16))),
                      SizedBox(height: scaleConfig.scale(4)),
                      Text(widget.subject.code, style: TextStyle(color: AppColors.darkTextSecondary, fontSize: scaleConfig.scale(12))),
                    ],
                  ),
                ),
                if (_isStatusLoading) const SizedBox(height: 30, width: 30, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary))))
                else Switch(
                    value: widget.subject.isOpen,
                    onChanged: (newValue) async {
                      setState(() => _isStatusLoading = true);
                      try {
                        await ref.read(subjectsRepositoryProvider).updateSubjectStatus(widget.subject.id!, newValue);
                        ref.invalidate(subjectsProvider(widget.subject.majorId!));
                      } finally {
                        if(mounted) setState(() => _isStatusLoading = false);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
              ],
            ),
            SizedBox(height: scaleConfig.scale(12)),
            Wrap(
              spacing: scaleConfig.scale(8), runSpacing: scaleConfig.scale(4),
              children: [
                Chip(label: Text('Level: ${widget.subject.level}'), backgroundColor: AppColors.primary.withOpacity(0.2), labelStyle: const TextStyle(color: AppColors.primary)),
                Chip(label: Text('Hours: ${widget.subject.hours}'), backgroundColor: AppColors.accent.withOpacity(0.2), labelStyle: const TextStyle(color: AppColors.accent)),
                Chip(label: Text(typeName), backgroundColor: Colors.teal.withOpacity(0.2), labelStyle: const TextStyle(color: Colors.teal)),
              ],
            ),
            const Divider(height: 32, color: AppColors.darkSurface),
            Opacity(
              opacity: widget.subject.isOpen ? 1.0 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Groups', style: TextStyle(fontWeight: FontWeight.w600, fontSize: scaleConfig.scale(14), color: AppColors.darkTextPrimary)),
                  SizedBox(height: scaleConfig.scale(12)),
                  groupsAsync.when(
                    data: (groups) => Column(
                      children: [
                        if (groups.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text('No groups available.', style: TextStyle(color: AppColors.darkTextSecondary))),
                        ...groups.map((group) => _GroupItem(group: group)),
                        SizedBox(height: scaleConfig.scale(12)),
                        if (widget.subject.isOpen)
                          Align(alignment: Alignment.center, child: TextButton.icon(
                              onPressed: () => showDialog(context: context, builder: (_) => _AddScheduleDialog(subjectId: widget.subject.id!)),
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              label: const Text('Add Group/Schedule', style: TextStyle(color: AppColors.primary)),
                            ),
                          ),
                      ],
                    ),
                    loading: () => const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                    error: (e, _) => Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
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

// --- GROUP ITEM ---
class _GroupItem extends ConsumerWidget {
  final SubjectGroup group;
  const _GroupItem({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ScaleConfig(context);
    final theoretical = group.schedules.where((s) => s.scheduleType == 'THEORETICAL');
    final practical = group.schedules.where((s) => s.scheduleType == 'PRACTICAL');
    return Container(
      padding: EdgeInsets.all(scaleConfig.scale(12)), margin: EdgeInsets.only(bottom: scaleConfig.scale(8)),
      decoration: BoxDecoration(color: AppColors.darkSurface.withOpacity(0.8), borderRadius: BorderRadius.circular(scaleConfig.scale(8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Group: ${group.groupCode}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary, fontSize: scaleConfig.scale(14))),
              IconButton(iconSize: 20, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                onPressed: () => showDialog(context: context, builder: (_) => _DeleteGroupConfirmationDialog(group: group))),
            ],
          ),
          const Divider(color: AppColors.darkBackground, height: 16),
          if (theoretical.isNotEmpty) ...[const Text('Theoretical:', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500)), ...theoretical.map((s) => ScheduleRow(schedule: s, subjectId: group.subjectId))],
          if (practical.isNotEmpty) ...[SizedBox(height: theoretical.isNotEmpty ? 8 : 0), const Text('Practical/Lab:', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w500)), ...practical.map((s) => ScheduleRow(schedule: s, subjectId: group.subjectId))],
        ],
      ),
    );
  }
}

// --- SCHEDULE ROW ---
class ScheduleRow extends ConsumerWidget {
  final Schedule schedule;
  final int subjectId;
  const ScheduleRow({super.key, required this.schedule, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 8.0),
      child: Row(
        children: [
          Expanded(child: Text('${schedule.dayOfWeek}: ${schedule.startTime} - ${schedule.endTime}', style: const TextStyle(color: AppColors.darkTextSecondary))),
          IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.edit, color: AppColors.accent),
            onPressed: () => showDialog(context: context, builder: (_) => _EditScheduleDialog(schedule: schedule, subjectId: subjectId))),
          IconButton(iconSize: 18, constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () {
              showDialog(context: context, builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: AppColors.darkSurface, title: const Text('Delete Schedule', style: TextStyle(color: AppColors.darkTextPrimary)),
                  content: Text('Delete this ${schedule.scheduleType.toLowerCase()} schedule?', style: const TextStyle(color: AppColors.darkTextSecondary)),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary))),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      onPressed: () async {
                        await ref.read(subjectsRepositoryProvider).deleteSchedule(schedule.id);
                        ref.refresh(subjectGroupsProvider(subjectId).future);
                        if(context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

// --- DELETE GROUP DIALOG ---
class _DeleteGroupConfirmationDialog extends ConsumerStatefulWidget {
  final SubjectGroup group;
  const _DeleteGroupConfirmationDialog({required this.group});
  @override
  ConsumerState<_DeleteGroupConfirmationDialog> createState() => _DeleteGroupConfirmationDialogState();
}
class _DeleteGroupConfirmationDialogState extends ConsumerState<_DeleteGroupConfirmationDialog> {
  bool _isDeleting = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface, title: const Text('Delete Group', style: TextStyle(color: AppColors.darkTextPrimary)),
      content: Text('Delete group ${widget.group.groupCode} and all its schedules? This cannot be undone.', style: const TextStyle(color: AppColors.darkTextSecondary)),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary))),
        TextButton(
          onPressed: _isDeleting ? null : () async {
            setState(() => _isDeleting = true);
            try {
              await ref.read(subjectsRepositoryProvider).deleteGroup(widget.group.id);
              ref.refresh(subjectGroupsProvider(widget.group.subjectId).future);
              if (mounted) Navigator.of(context).pop();
            } catch(e) {
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error));
              }
            }
          },
          child: _isDeleting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error)) : const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}

// --- ADD SCHEDULE DIALOG ---
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
  final _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final _types = ['THEORETICAL', 'PRACTICAL'];
  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now(), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.darkBackground, onSurface: AppColors.darkTextPrimary), dialogBackgroundColor: AppColors.darkSurface), child: child!));
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start and end time.'), backgroundColor: AppColors.error)); return;
    }
    if (_startTime!.hour > _endTime!.hour || (_startTime!.hour == _endTime!.hour && _startTime!.minute >= _endTime!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time.'), backgroundColor: AppColors.error)); return;
    }
    setState(() => _isLoading = true);
    final startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
    final groupCode = _groupCodeController.text.trim();
    try {
      final conflict = await ref.read(subjectsRepositoryProvider).checkGroupConflict(subjectId: widget.subjectId, groupCode: groupCode, scheduleType: _selectedType!, dayOfWeek: _selectedDay!, startTime: startTimeStr, endTime: endTimeStr,);
      if (conflict != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(conflict), backgroundColor: AppColors.error, duration: const Duration(seconds: 4)));
        setState(() => _isLoading = false); return;
      }
      await ref.read(subjectsRepositoryProvider).addGroupWithSchedule(subjectId: widget.subjectId, groupCode: groupCode, dayOfWeek: _selectedDay!, startTime: startTimeStr, endTime: endTimeStr, scheduleType: _selectedType!,);
      ref.refresh(subjectGroupsProvider(widget.subjectId).future);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }
  @override
  void dispose() { _groupCodeController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(labelStyle: const TextStyle(color: AppColors.darkTextSecondary), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkTextSecondary.withOpacity(0.5))), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)));
    return AlertDialog(
      backgroundColor: AppColors.darkSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Add Group/Schedule', style: TextStyle(color: AppColors.darkTextPrimary)),
      content: Form(key: _formKey, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _groupCodeController, decoration: inputDecoration.copyWith(labelText: 'Group Code (e.g., TH01)'), style: const TextStyle(color: AppColors.darkTextPrimary), validator: (v) => (v==null||v.isEmpty)?'Cannot be empty':null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: _selectedDay, hint: const Text('Select Day', style: TextStyle(color: AppColors.darkTextSecondary)), onChanged: (v)=>setState(()=>_selectedDay=v), items: _days.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(), decoration:inputDecoration, dropdownColor:AppColors.darkBackground, style:const TextStyle(color:AppColors.darkTextPrimary), validator:(v)=>v==null?'Please select':null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: _selectedType, hint: const Text('Select Type', style: TextStyle(color: AppColors.darkTextSecondary)), onChanged: (v)=>setState(()=>_selectedType=v), items: _types.map((t)=>DropdownMenuItem(value:t,child:Text(t))).toList(), decoration:inputDecoration, dropdownColor:AppColors.darkBackground, style:const TextStyle(color:AppColors.darkTextPrimary), validator:(v)=>v==null?'Please select':null),
              const SizedBox(height: 16),
              ListTile(contentPadding:EdgeInsets.zero, title:Text('Start: ${_startTime?.format(context)??'Not set'}', style:const TextStyle(color:AppColors.darkTextSecondary)), trailing:const Icon(Icons.access_time,color:AppColors.primary), onTap:()=>_pickTime(true)),
              ListTile(contentPadding:EdgeInsets.zero, title:Text('End: ${_endTime?.format(context)??'Not set'}', style:const TextStyle(color:AppColors.darkTextSecondary)), trailing:const Icon(Icons.access_time,color:AppColors.primary), onTap:()=>_pickTime(false)),
            ],
      ))),
      actions: [
        TextButton(onPressed:()=>Navigator.of(context).pop(), child: const Text('Cancel', style:TextStyle(color:AppColors.darkTextSecondary))),
        ElevatedButton(onPressed:_isLoading?null:_submitForm, style:ElevatedButton.styleFrom(backgroundColor:AppColors.primary, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))), child:_isLoading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Save', style:TextStyle(color:Colors.white))),
      ],
    );
  }
}

// --- EDIT SCHEDULE DIALOG ---
class _EditScheduleDialog extends ConsumerStatefulWidget {
  final Schedule schedule;
  final int subjectId;
  const _EditScheduleDialog({required this.schedule, required this.subjectId});
  @override
  ConsumerState<_EditScheduleDialog> createState() => _EditScheduleDialogState();
}
class _EditScheduleDialogState extends ConsumerState<_EditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDay;
  TimeOfDay? _startTime, _endTime;
  bool _isLoading = false;
  final _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _selectedDay = s.dayOfWeek;
    final start = s.startTime.split(':'); _startTime = TimeOfDay(hour: int.parse(start[0]), minute: int.parse(start[1]));
    final end = s.endTime.split(':'); _endTime = TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1]));
  }
  Future<void> _pickTime(bool isStart) async {
    final initial = isStart?(_startTime??TimeOfDay.now()):(_endTime??TimeOfDay.now());
    final picked = await showTimePicker(context: context, initialTime: initial, builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.darkBackground, onSurface: AppColors.darkTextPrimary), dialogBackgroundColor: AppColors.darkSurface), child: child!));
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select times.'), backgroundColor: AppColors.error)); return;
    }
    setState(() => _isLoading = true);
    final startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
    try {
      final conflict = await ref.read(subjectsRepositoryProvider).checkGroupConflict(
        subjectId: widget.subjectId, groupCode: "N/A",
        scheduleType: widget.schedule.scheduleType, dayOfWeek: _selectedDay!, startTime: startTimeStr, endTime: endTimeStr,
        editingScheduleId: widget.schedule.id,
      );
      if (conflict != null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(conflict), backgroundColor: AppColors.error));
        setState(() => _isLoading = false); return;
      }
      await ref.read(subjectsRepositoryProvider).updateSchedule(widget.schedule.id, dayOfWeek: _selectedDay!, startTime: startTimeStr, endTime: endTimeStr,);
      ref.refresh(subjectGroupsProvider(widget.subjectId).future);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(labelStyle: const TextStyle(color: AppColors.darkTextSecondary), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkTextSecondary.withOpacity(0.5))), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)));
    return AlertDialog(
      backgroundColor: AppColors.darkSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Edit Schedule', style: TextStyle(color: AppColors.darkTextPrimary)),
      content: Form(key: _formKey, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(value: _selectedDay, hint: const Text('Day', style: TextStyle(color: AppColors.darkTextSecondary)), onChanged: (v)=>setState(()=>_selectedDay=v), items: _days.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(), decoration:inputDecoration, dropdownColor:AppColors.darkBackground, style:const TextStyle(color:AppColors.darkTextPrimary), validator:(v)=>v==null?'Please select':null),
              const SizedBox(height: 16),
              ListTile(contentPadding:EdgeInsets.zero, title:Text('Start: ${_startTime?.format(context)??'Not set'}', style:const TextStyle(color:AppColors.darkTextSecondary)), trailing:const Icon(Icons.access_time,color:AppColors.primary), onTap:()=>_pickTime(true)),
              ListTile(contentPadding:EdgeInsets.zero, title:Text('End: ${_endTime?.format(context)??'Not set'}', style:const TextStyle(color:AppColors.darkTextSecondary)), trailing:const Icon(Icons.access_time,color:AppColors.primary), onTap:()=>_pickTime(false)),
            ],
      ))),
      actions: [
        TextButton(onPressed:()=>Navigator.of(context).pop(), child: const Text('Cancel', style:TextStyle(color:AppColors.darkTextSecondary))),
        ElevatedButton(onPressed:_isLoading?null:_submitForm, style:ElevatedButton.styleFrom(backgroundColor:AppColors.primary, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))), child:_isLoading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Update', style:TextStyle(color:Colors.white))),
      ],
    );
  }
}