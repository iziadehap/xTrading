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

    // If no cached URL exists, set it to the default from config
    if (!_prefs!.containsKey(_baseUrlKey) && Config.defaultBaseUrl.isNotEmpty) {
      await setBaseUrl(Config.defaultBaseUrl);
    }
  }

  String getBaseUrl() {
    // Return cached URL if exists, otherwise return default
    return _prefs?.getString(_baseUrlKey) ?? Config.defaultBaseUrl;
  }

  Future<bool> setBaseUrl(String url) async {
    if (_prefs == null) await init();

    // Save to cache (SharedPreferences)
    final success = await _prefs!.setString(_baseUrlKey, url);

    // Optionally update the default config as well
    if (success && url.isNotEmpty) {
      Config.defaultBaseUrl = url;
    }

    return success;
  }

  Future<bool> resetToDefault() async {
    // Reset to the original environment variable default
    // You might want to reload from .env here if needed
    return await setBaseUrl(Config.defaultBaseUrl);
  }

  // Check if URL is cached (different from default)
  bool isUrlCached() {
    final cachedUrl = _prefs?.getString(_baseUrlKey);
    final defaultUrl = Config.defaultBaseUrl;
    return cachedUrl != null && cachedUrl.isNotEmpty && cachedUrl != defaultUrl;
  }

  // Clear cached URL and reset to environment default
  Future<bool> clearCache() async {
    if (_prefs == null) await init();
    return await _prefs!.remove(_baseUrlKey);
  }
}
