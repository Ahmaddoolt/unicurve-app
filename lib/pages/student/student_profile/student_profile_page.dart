// lib/pages/student/student_profile/student_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_floadt_action_button.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'my_profile_title'.tr,
      actions: [
        // This button will be disabled visually by Flutter if onPressed is null
        IconButton(
          tooltip: 'view_degree_progress_tooltip'.tr,
          icon: const Icon(Icons.pie_chart_outline),
          onPressed: (profileAsync.hasValue && profileAsync.value != null)
              ? () {
                  showRequirementsDialog(
                    context,
                    scaleConfig,
                    profileAsync.value!,
                  );
                }
              : null, // Disable button while loading or on error
        ),
        IconButton(
          tooltip: 'settings_tooltip'.tr,
          icon: const Icon(Icons.settings_outlined),
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
    );

    final bodyContent = GlassLoadingOverlay(
      isLoading: profileAsync.isLoading && !profileAsync.hasValue,
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(academicProfileProvider.notifier).fetchProfileData(),
        color: AppColors.primary,
        backgroundColor: theme.scaffoldBackgroundColor,
        child: profileAsync.when(
          data: (profile) {
            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                scaleConfig.scale(12),
                scaleConfig.scale(12),
                scaleConfig.scale(12),
                scaleConfig.scale(120),
              ),
              children: [
                ProfileHeader(profile: profile),
                SizedBox(height: scaleConfig.scale(15)),
                AcademicRecord(profile: profile),
              ],
            );
          },
          // --- THE KEY FIX IS HERE ---
          // Instead of SizedBox.shrink(), we now build the skeleton UI.
          loading: () {
            // Passing null tells the widgets to render their skeleton state.
            return ListView(
              padding: EdgeInsets.fromLTRB(
                scaleConfig.scale(12),
                scaleConfig.scale(12),
                scaleConfig.scale(12),
                scaleConfig.scale(120),
              ),
              children: [
                const ProfileHeader(profile: null),
                SizedBox(height: scaleConfig.scale(15)),
                const AcademicRecord(profile: null),
              ],
            );
          },
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'error_generic'.trParams({'error': error.toString()}),
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    final fab = Padding(
      padding:
          const EdgeInsets.only(bottom: 70.0), // Add space above bottom nav
      child: AnimatedOpacity(
        opacity: isFabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: CustomFAB(
          tooltip: 'add_mark_button'.tr,
          onPressed: () async {
            if (!isFabVisible || !profileAsync.hasValue) return;

            final success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => AddSubjectMarkPage(
                  takenSubjects: profileAsync.value!.takenSubjects,
                  universityType: profileAsync.value!.universityType,
                ),
              ),
            );
            if (success == true) {
              ref.invalidate(academicProfileProvider);
            }
          },
        ),
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: fab,
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
        floatingActionButton: fab,
      );
    }
  }
}