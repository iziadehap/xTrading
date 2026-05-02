// Default configuration - used as fallback
// User can override via Settings screen (saved to SharedPreferences)
class Config {
  // Default base URL from environment variables
  static String defaultBaseUrl = '';

  // Initialize with environment variable
  static void initializeFromEnv(String url) {
    if (url.isNotEmpty) {
      defaultBaseUrl = url;
    }
  }
}
