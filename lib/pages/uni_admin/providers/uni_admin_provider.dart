// lib/providers/uni_admin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider to fetch the current admin's profile data
final adminProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception("User not authenticated.");
  }

  // Fetch admin details
  final adminResponse = await supabase
      .from('uni_admin')
      .select('*, universities(*)') // Use Supabase to join tables
      .eq('user_id', userId)
      .single();

  return adminResponse;
});