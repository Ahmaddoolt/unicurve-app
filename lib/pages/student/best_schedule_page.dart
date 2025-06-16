import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicurve/pages/student/providers/schedule_generator_provider.dart';

class BestSchedulePage extends ConsumerWidget {
  const BestSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleGeneratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Schedule'),
      ),
      body: scheduleAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Generating your optimal schedule...'),
              Text('This might take a moment.'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Text('Failed to generate schedule:\n$err', textAlign: TextAlign.center),
        ),
        data: (scheduleResult) {
          if (scheduleResult.scheduledCourses.isEmpty) {
            return const Center(child: Text('Could not generate a schedule with the available subjects.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Optimal Schedule Found!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total Hours: ${scheduleResult.totalHours}', style: const TextStyle(fontSize: 16)),
                      Text('Number of Courses: ${scheduleResult.scheduledCourses.length}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // List of Courses
              ...scheduleResult.scheduledCourses.map((course) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(course.subject['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${course.subject['code']} - ${course.subject['hours']} Hours'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Group Code: ${course.group['group_code']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Divider(),
                            ...course.schedules.map((slot) {
                              return Text('${slot['day_of_week']}: ${slot['start_time']} - ${slot['end_time']} (${slot['schedule_type']})');
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}