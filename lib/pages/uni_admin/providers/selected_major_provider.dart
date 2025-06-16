import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the ID of the major the admin has selected from [SelectMajorPage].
///
/// Pages like [ManageSubjectsPage] can watch this provider to get the
/// current context without needing the ID passed through constructors.
final selectedMajorIdProvider = StateProvider<int?>((ref) => null);