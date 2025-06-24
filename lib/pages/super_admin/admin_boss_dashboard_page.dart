import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/domain/models/admin_uni.dart';
import 'package:unicurve/domain/models/uni_admin_request.dart';
import 'package:unicurve/domain/models/university.dart';

class BossAdminPage extends StatefulWidget {
  const BossAdminPage({super.key});

  @override
  State<BossAdminPage> createState() => _BossAdminPageState();
}

class _BossAdminPageState extends State<BossAdminPage> {
  late Future<List<UniAdmin>> _pendingRequestsFuture;

  @override
  void initState() {
    super.initState();
    _pendingRequestsFuture = _fetchPendingRequests();
  }

  Future<List<UniAdmin>> _fetchPendingRequests() async {
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
      throw Exception('boss_admin_error_db'.trParams({'error': e.message}));
    }
  }

  void _showFeedbackSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _approveRequest(UniAdmin request) async {
    try {
      final existingUni =
          await Supabase.instance.client
              .from('universities')
              .select('id')
              .eq('short_name', request.universityShortName)
              .maybeSingle();

      if (existingUni != null) {
        _showFeedbackSnackbar(
          'boss_admin_error_short_name_exists'.trParams({
            'shortName': request.universityShortName,
          }),
          isError: true,
        );
        return;
      }

      final university = University(
        name: request.universityName,
        shortName: request.universityShortName,
        uniType: request.universityType,
        uniLocation: request.universityLocation,
      );

      final universityResponse =
          await Supabase.instance.client
              .from('universities')
              .insert(university.toJson())
              .select()
              .single();

      final insertedUniversity = University.fromJson(universityResponse);

      final admin = Admin(
        userId: request.userId!,
        firstName: request.firstName,
        lastName: request.lastName,
        phoneNumber: request.phoneNumber,
        email: request.email,
        position: request.position,
        universityId: insertedUniversity.id!,
      );

      await Supabase.instance.client.from('uni_admin').insert(admin.toJson());

      await Supabase.instance.client
          .from('add_uni_pending_requests')
          .update({'is_approved': true})
          .eq('id', request.id!);

      _showFeedbackSnackbar('boss_admin_request_approved'.tr);
      setState(() {
        _pendingRequestsFuture = _fetchPendingRequests();
      });
    } on PostgrestException catch (e) {
      _showFeedbackSnackbar(
        'boss_admin_error_db'.trParams({'error': e.message}),
        isError: true,
      );
    } catch (e) {
      _showFeedbackSnackbar(
        'error_unexpected'.trParams({'error': e.toString()}),
        isError: true,
      );
    }
  }

  Future<void> _disapproveRequest(int requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('boss_admin_confirm_disapprove_title'.tr),
            content: Text('boss_admin_confirm_disapprove_content'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'boss_admin_disapprove_button'.tr,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('add_uni_pending_requests')
          .delete()
          .eq('id', requestId);
      _showFeedbackSnackbar('boss_admin_request_disapproved'.tr);
      setState(() {
        _pendingRequestsFuture = _fetchPendingRequests();
      });
    } on PostgrestException catch (e) {
      _showFeedbackSnackbar(
        'boss_admin_error_db'.trParams({'error': e.message}),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'boss_admin_page_title'.tr,
        centerTitle: true,
      ),
      body: FutureBuilder<List<UniAdmin>>(
        future: _pendingRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'boss_admin_error_loading'.trParams({
                  'error': snapshot.error.toString(),
                }),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _EmptyState();
          }
          final requests = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _pendingRequestsFuture = _fetchPendingRequests();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _RequestCard(
                  request: request,
                  onApprove: () => _approveRequest(request),
                  onDisapprove: () => _disapproveRequest(request.id!),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final UniAdmin request;
  final VoidCallback onApprove;
  final VoidCallback onDisapprove;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onDisapprove,
  });

  String getTranslatedLocation(String locationValue) {
    final key = 'country_${locationValue.toLowerCase().replaceAll(' ', '_')}';

    final translated = key.tr;
    if (translated == key) {
      return locationValue;
    }
    return translated;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            // ignore: deprecated_member_use
            color: theme.colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '${request.firstName} ${request.lastName}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'boss_admin_applicant_details'.tr),
                _buildDetailRow('boss_admin_label_email'.tr, request.email),
                _buildDetailRow(
                  'boss_admin_label_phone'.tr,
                  request.phoneNumber,
                ),
                _buildDetailRow(
                  'boss_admin_label_position'.tr,
                  request.position,
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'boss_admin_university_details'.tr),
                _buildDetailRow(
                  'boss_admin_label_uni_name'.tr,
                  request.universityName,
                ),
                _buildDetailRow(
                  'boss_admin_label_short_name'.tr,
                  request.universityShortName,
                ),
                _buildDetailRow(
                  'boss_admin_label_type'.tr,
                  request.universityType.tr,
                ),
                _buildDetailRow(
                  'boss_admin_label_location'.tr,
                  getTranslatedLocation(request.universityLocation),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: onDisapprove,
                    text: 'boss_admin_disapprove_button'.tr,
                    backgroundColor: AppColors.error,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: onApprove,
                    text: 'boss_admin_approve_button'.tr,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'boss_admin_no_requests'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
