import 'package:shared_preferences/shared_preferences.dart';

class UniversityCacheService {
  static const _uniTypeKey = 'cached_university_type';

  Future<void> saveUniversityType(String uniType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uniTypeKey, uniType);
  }

  Future<String?> getUniversityType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_uniTypeKey);
  }

  Future<void> clearUniversityType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uniTypeKey);
  }
}