import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});
