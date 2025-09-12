import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/domain/models/student.dart';
import 'package:unicurve/domain/models/uni_admin_request.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isRememberMe = prefs.getBool('isRememberMe') ?? false;
    final uid = prefs.getString('uid');
    if (isRememberMe && uid != null) {
      return {'isRememberMe': isRememberMe, 'uid': uid};
    }
    return null;
  }

  Future<void> saveCredentials({
    required bool isRememberMe,
    required String uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRememberMe', isRememberMe);
    await prefs.setString('uid', uid);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isRememberMe');
    await prefs.remove('uid');
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<String?> signUp({required Student student}) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: student.email,
        password: student.password!,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception('Failed to create user');
      }

      await _supabase.from('students').insert({
        'user_id': userId,
        'first_name': student.firstName,
        'last_name': student.lastName,
        'uni_number': student.uniNumber,
        'university_id': student.universityId,
        'major_id': student.majorId,
      });

      return userId;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<String?> submitAdminRequest({required UniAdmin uniAdmin}) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: uniAdmin.email,
        password: uniAdmin.password!,
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw AuthException('Failed to create user');
      }

      final data = {...uniAdmin.toJson(), 'user_id': userId};

      await _supabase.from('add_uni_pending_requests').insert(data);

      return userId;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<List<dynamic>> getUniversities(String location) async {
    try {
      return await _supabase
          .from('universities')
          .select()
          .eq('uni_location', location);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<List<dynamic>> getMajors(int universityId) async {
    try {
      return await _supabase
          .from('majors')
          .select()
          .eq('university_id', universityId);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> getUserRole(String userId) async {
    try {
      final response =
          await _supabase
              .from('uni_admin')
              .select('id, university_id, position')
              .eq('user_id', userId)
              .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
