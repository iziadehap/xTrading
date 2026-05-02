// Default configuration - used as fallback
// User can override via Settings screen (saved to SharedPreferences)
class Config {
  static const String defaultBaseUrl = String.fromEnvironment(
    'BaseUrl',
    defaultValue: 'https://your-server-ip:8080',
  );
}
