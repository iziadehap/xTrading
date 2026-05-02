import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class SettingsService {
  static const String _baseUrlKey = 'base_url';

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getBaseUrl() {
    return _prefs?.getString(_baseUrlKey) ?? Config.defaultBaseUrl;
  }

  Future<bool> setBaseUrl(String url) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_baseUrlKey, url);
  }

  Future<bool> resetToDefault() async {
    return await setBaseUrl(Config.defaultBaseUrl);
  }
}
