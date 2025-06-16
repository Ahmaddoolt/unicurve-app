import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/pages/auth/login/login_page.dart';
import 'package:unicurve/pages/home/home_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? "User";

    Future<void> logout(BuildContext context) async {
      final authService = AuthService();
      try {
        await authService.signOut();
        await authService.clearCredentials();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
        }
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "Welcome, $email",
        actions: [LogoutButton(onPressed: () => logout(context))],
      ),
      body: const HomeContent(),
    );
  }
}
