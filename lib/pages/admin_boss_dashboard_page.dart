import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/domain/models/admin_uni.dart';
import 'package:unicurve/domain/models/uni_admin_request.dart'; // Existing UniAdmin model
import 'package:unicurve/domain/models/university.dart'; // New University model

class BossAdminPage extends StatefulWidget {
  const BossAdminPage({super.key});

  @override
  State<BossAdminPage> createState() => _BossAdminPageState();
}

class _BossAdminPageState extends State<BossAdminPage> {
  Future<List<UniAdmin>> _fetchPendingRequests() async {
    // Check if user is authenticated
    if (Supabase.instance.client.auth.currentUser == null) {
      return [];
    }
    try {
      final response = await Supabase.instance.client
          .from('add_uni_pending_requests')
          .select()
          .eq('is_approved', false);
      return (response as List<dynamic>)
          .map((json) => UniAdmin.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<void> _approveRequest(UniAdmin request) async {
    try {
      // Create University object
      final university = University(
        name: request.universityName,
        shortName: request.universityShortName,
        uniType: request.universityType,
        uniLocation: request.universityLocation,
      );

      // Insert university
      final universityResponse = await Supabase.instance.client
          .from('universities')
          .insert(university.toJson())
          .select()
          .single();

      final insertedUniversity = University.fromJson(universityResponse);

      // Create Admin object
      final admin = Admin(
        userId: request.userId!,
        firstName: request.firstName,
        lastName: request.lastName,
        phoneNumber: request.phoneNumber,
        email: request.email,
        position: request.position,
        universityId: insertedUniversity.id!,
      );

      // Insert admin
      await Supabase.instance.client.from('uni_admin').insert(admin.toJson());

      // Mark as approved
      await Supabase.instance.client
          .from('add_uni_pending_requests')
          .update({'is_approved': true})
          .eq('id', request.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved')),
        );
        setState(() {}); // Refresh the list
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _disapproveRequest(int requestId) async {
    try {
      await Supabase.instance.client
          .from('add_uni_pending_requests')
          .delete()
          .eq('id', requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request disapproved and deleted')),
        );
        setState(() {}); // Refresh the list
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Boss Admin - Pending Requests',
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<UniAdmin>>(
              future: _fetchPendingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final pendingRequests = snapshot.data ?? [];
                if (pendingRequests.isEmpty) {
                  return const Center(child: Text('No pending requests'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${request.firstName} ${request.lastName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Email: ${request.email}'),
                            Text('Phone: ${request.phoneNumber}'),
                            Text('Position: ${request.position}'),
                            Text('University: ${request.universityName}'),
                            Text('Short Name: ${request.universityShortName}'),
                            Text('Type: ${request.universityType}'),
                            Text('Location: ${request.universityLocation}'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    onPressed: () => _approveRequest(request),
                                    text: 'Approve',
                                    backgroundColor: Colors.green,
                                    textColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomButton(
                                    onPressed: () => _disapproveRequest(request.id!),
                                    text: 'Disapprove',
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}