import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version/version.dart';

class UpdateCheckResult {
  final bool isForced;
  final String storeUrl;

  UpdateCheckResult({required this.isForced, required this.storeUrl});
}

class AppUpdateService {
  final _supabase = Supabase.instance.client;
  static const String _launchCountKey = 'app_launch_count';
  static const int _checkInterval = 20;

  Future<UpdateCheckResult> anageUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();

    int currentLaunchCount = prefs.getInt(_launchCountKey) ?? 0;

    currentLaunchCount++;

    if (currentLaunchCount >= _checkInterval) {
      debugPrint(
        "Update check triggered: Launch count reached $_checkInterval.",
      );
      await prefs.setInt(_launchCountKey, 0);
      return _performRemoteUpdateCheck();
    } else {
      await prefs.setInt(_launchCountKey, currentLaunchCount);
      debugPrint(
        "Skipping update check. Launch count is $currentLaunchCount/$_checkInterval.",
      );
      return UpdateCheckResult(isForced: false, storeUrl: '');
    }
  }

  Future<UpdateCheckResult> _performRemoteUpdateCheck() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final platform =
          kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');

      final remoteConfig =
          await _supabase
              .from('app_config')
              .select('minimum_version, store_url')
              .eq('platform', platform)
              .single();

      final minimumVersionStr = remoteConfig['minimum_version'] as String;
      final storeUrl = remoteConfig['store_url'] as String;
      final minimumVersion = Version.parse(minimumVersionStr);

      final isForced = minimumVersion > currentVersion;

      return UpdateCheckResult(isForced: isForced, storeUrl: storeUrl);
    } catch (e) {
      debugPrint("Remote update check failed: $e");
      return UpdateCheckResult(isForced: false, storeUrl: '');
    }
  }
}
