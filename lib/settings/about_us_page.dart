// // lib/pages/settings/about_us_page.dart

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:unicurve/core/utils/colors.dart';
// import 'package:unicurve/core/utils/custom_appbar.dart';
// import 'package:unicurve/core/utils/glass_card.dart';
// import 'package:unicurve/core/utils/glass_loading_overlay.dart';
// import 'package:unicurve/core/utils/gradient_scaffold.dart';
// import 'package:unicurve/core/utils/scale_config.dart';
// import 'package:unicurve/domain/models/app_hub_model.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';


// class AboutUsPage extends StatefulWidget {
//   const AboutUsPage({super.key});

//   @override
//   State<AboutUsPage> createState() => _AboutUsPageState();
// }

// class _AboutUsPageState extends State<AboutUsPage> {
//   late final Future<List<MyAppInfo>> _myAppsFuture;
//   final String? _supabaseUrl = dotenv.env['SUPABASE_URL'];

//   @override
//   void initState() {
//     super.initState();
//     _myAppsFuture = _fetchMyApps();
//   }

//   Future<List<MyAppInfo>> _fetchMyApps() async {
//     try {
//       final response = await Supabase.instance.client
//           .from('my_apps')
//           .select()
//           .order('display_order', ascending: true);

//       return (response as List<dynamic>)
//           .map((json) => MyAppInfo.fromJson(json))
//           .toList();
//     } catch (e) {
//       throw Exception('Failed to load app information: $e');
//     }
//   }

//   Future<void> _launchURL(String? urlString) async {
//     if (urlString == null || urlString.isEmpty) return;
//     final Uri url = Uri.parse(urlString);
//     if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not launch $urlString')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     final appBar = CustomAppBar(
//       useGradient: !isDarkMode,
//       title: 'About Us'.tr, // Add this to translations
//     );

//     final bodyContent = FutureBuilder<List<MyAppInfo>>(
//       future: _myAppsFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const GlassLoadingOverlay(isLoading: true, child: SizedBox.expand());
//         }
//         if (snapshot.hasError) {
//           return Center(
//             child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
//           );
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No applications found.'));
//         }

//         final myApps = snapshot.data!;

//         return ListView.builder(
//           padding: const EdgeInsets.all(16.0),
//           itemCount: myApps.length,
//           itemBuilder: (context, index) {
//             final app = myApps[index];
//             // This line now works correctly because app.logoPath is just the filename
//             final logoUrl = '$_supabaseUrl/storage/v1/object/public/app_logos/${app.logoPath}';
            
//             return _MyAppCard(
//               app: app, 
//               logoUrl: logoUrl, 
//               onPlayStoreTap: () => _launchURL(app.playStoreUrl),
//               onAppStoreTap: () => _launchURL(app.appStoreUrl),
//             );
//           },
//         );
//       },
//     );

//     if (isDarkMode) {
//       return GradientScaffold(appBar: appBar, body: bodyContent);
//     } else {
//       return Scaffold(
//         backgroundColor: theme.scaffoldBackgroundColor,
//         appBar: appBar,
//         body: bodyContent,
//       );
//     }
//   }
// }

// class _MyAppCard extends StatelessWidget {
//   final MyAppInfo app;
//   final String logoUrl;
//   final VoidCallback? onPlayStoreTap;
//   final VoidCallback? onAppStoreTap;

//   const _MyAppCard({
//     required this.app,
//     required this.logoUrl,
//     this.onPlayStoreTap,
//     this.onAppStoreTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final scaleConfig = context.scaleConfig;
//     final theme = Theme.of(context);

//     return GlassCard(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             // App Logo
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(
//                 logoUrl,
//                 width: scaleConfig.scale(60),
//                 height: scaleConfig.scale(60),
//                 fit: BoxFit.cover,
//                 loadingBuilder: (context, child, progress) {
//                   return progress == null ? child : const Center(child: CircularProgressIndicator());
//                 },
//                 errorBuilder: (context, error, stack) {
//                   return const Icon(Icons.image_not_supported, size: 60);
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             // App Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(app.name, style: theme.textTheme.titleMedium),
//                   Text(app.type, style: theme.textTheme.bodySmall),
//                 ],
//               ),
//             ),
            
//             // Store Icons
//             if (app.playStoreUrl != null)
//               IconButton(
//                 onPressed: onPlayStoreTap,
//                 icon: const Icon(Icons.android),
//                 iconSize: 28,
//                 color: const Color(0xFF00DEFF),
//                 tooltip: 'View on Google Play',
//               ),
//             if (app.appStoreUrl != null)
//               IconButton(
//                 onPressed: onAppStoreTap,
//                 icon: const Icon(Icons.apple),
//                 iconSize: 30,
//                 color: theme.textTheme.bodyMedium?.color,
//                 tooltip: 'View on App Store',
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }