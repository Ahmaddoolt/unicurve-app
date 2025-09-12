import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/pages/student/student_profile/add_subject_mark_page.dart';
import 'package:unicurve/pages/student/student_profile/providers/academic_profile_provider.dart';
import 'package:unicurve/pages/student/student_profile/student_profile_widgets.dart';
import 'package:unicurve/pages/student/student_setting_page.dart';

final isFabVisibleProvider = StateProvider<bool>((ref) => true);

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final isFabVisible = ref.read(isFabVisibleProvider);
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (isFabVisible) {
        ref.read(isFabVisibleProvider.notifier).state = false;
      }
    } else {
      if (!isFabVisible) {
        ref.read(isFabVisibleProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final profileAsync = ref.watch(academicProfileProvider);
    final isFabVisible = ref.watch(isFabVisibleProvider);

    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        title: Text(
          'my_profile_title'.tr,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: darkerColor,
        actions: [
          if (profileAsync.hasValue)
            IconButton(
              tooltip: 'view_degree_progress_tooltip'.tr,
              icon: const Icon(
                Icons.pie_chart_outline,
                color: AppColors.primary,
              ),
              onPressed: () {
                showRequirementsDialog(
                  context,
                  scaleConfig,
                  profileAsync.value!,
                );
              },
            ),
          IconButton(
            tooltip: 'settings_tooltip'.tr,
            icon: const Icon(Icons.settings_outlined, color: AppColors.accent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error:
            (error, stack) => Center(
              child: Text(
                'error_generic'.trParams({'error': error.toString()}),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        data: (profile) {
          return RefreshIndicator(
            onRefresh:
                () =>
                    ref
                        .read(academicProfileProvider.notifier)
                        .fetchProfileData(),
            color: AppColors.primary,
            backgroundColor: darkerColor,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(scaleConfig.scale(12)),
              children: [
                ProfileHeader(profile: profile),
                SizedBox(height: scaleConfig.scale(20)),
                AcademicRecord(profile: profile),
                SizedBox(height: scaleConfig.scale(80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: isFabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          heroTag: 'addMarkFab',
          onPressed: () async {
            if (!isFabVisible || !profileAsync.hasValue) return;

            final success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddSubjectMarkPage(
                      takenSubjects: profileAsync.asData!.value.takenSubjects,
                      universityType: profileAsync.asData!.value.universityType,
                    ),
              ),
            );
            if (success == true) {
              ref.invalidate(academicProfileProvider);
            }
          },
          label: Text('add_mark_button'.tr),
          icon: const Icon(Icons.add_chart),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}
