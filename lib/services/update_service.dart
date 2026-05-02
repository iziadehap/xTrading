import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// ──────────────────────────────────────────────────────────────────
///  GitHub Releases Integration for App Updates
///  Uses GitHub Releases API to check for updates and download APK
/// ──────────────────────────────────────────────────────────────────

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String releaseNotes;
  final String downloadUrl;
  final int fileSize;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSize,
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  // Get GitHub configuration from environment variables
  String get _owner => dotenv.get('GITHUB_OWNER', fallback: 'your-username');
  String get _repo => dotenv.get('GITHUB_REPO', fallback: 'your-repo');
  String get _githubToken => dotenv.get('GITHUB_TOKEN', fallback: '');

  // GitHub API URL
  String get _releasesUrl =>
      'https://api.github.com/repos/$_owner/$_repo/releases';

  // ── Check for update ──────────────────────────────────────────────
  /// Returns [UpdateInfo] when an update is available, null otherwise.
  Future<UpdateInfo?> check() async {
    // Only run on Android — iOS uses App Store
    if (!Platform.isAndroid) return null;

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      // Prepare headers (include token if available)
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
      };
      if (_githubToken.isNotEmpty) {
        headers['Authorization'] = 'token $_githubToken';
      }

      // Fetch releases from GitHub API
      final response = await http
          .get(Uri.parse(_releasesUrl), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('⚠️ GitHub API error: ${response.statusCode}');
        return null;
      }

      final List<dynamic> releases = json.decode(response.body);
      if (releases.isEmpty) {
        print('ℹ️ No releases found in repository');
        return null;
      }

      // Find the latest release
      Map<String, dynamic>? latestRelease;
      for (final release in releases) {
        if (latestRelease == null ||
            DateTime.parse(
              release['published_at'],
            ).isAfter(DateTime.parse(latestRelease['published_at']))) {
          latestRelease = release as Map<String, dynamic>;
        }
      }

      if (latestRelease == null) {
        print('ℹ️ No valid release found');
        return null;
      }

      // Extract version from tag (remove 'v' prefix if present)
      String latestVersion = latestRelease['tag_name'] ?? '';
      if (latestVersion.startsWith('v')) {
        latestVersion = latestVersion.substring(1);
      }

      // Check if this is a newer version
      if (_isNewer(latestVersion, currentVersion)) {
        // Find APK asset in the release
        String? downloadUrl;
        int fileSize = 0;

        final assets = latestRelease['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetName = asset['name'] as String? ?? '';
          if (assetName.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            fileSize = asset['size'] as int? ?? 0;
            break;
          }
        }

        if (downloadUrl == null) {
          print('ℹ️ No APK file found in release ${latestRelease['tag_name']}');
          return null;
        }

        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          forceUpdate: false, // GitHub releases don't typically force updates
          releaseNotes: latestRelease['body'] ?? 'No release notes available.',
          downloadUrl: downloadUrl,
          fileSize: fileSize,
        );
      }

      return null; // already up to date
    } catch (e) {
      // Never crash the app because of an update check failure
      print('⚠️ UpdateService.check() error: $e');
      return null;
    }
  }

  // ── Download + Install ─────────────────────────────────────────────
  /// Streams download progress via [onProgress] (0.0 → 1.0).
  /// Returns the downloaded file path for manual installation.
  /// Throws on error so the caller can show a retry option.
  Future<String> downloadAndInstall({
    required UpdateInfo info,
    required void Function(double progress) onProgress,
  }) async {
    try {
      // Choose save path
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/update_v${info.latestVersion}.apk';
      final file = File(filePath);

      // Download APK with progress using http
      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      final streamedResponse = await request.send();

      final contentLength = streamedResponse.contentLength ?? 0;
      final bytes = <int>[];

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0) {
          onProgress(bytes.length / contentLength);
        }
      }

      // Write to file
      await file.writeAsBytes(bytes);

      // Return file path for manual installation
      if (await file.exists()) {
        return filePath;
      } else {
        throw Exception('Downloaded file not found at $filePath');
      }
    } catch (e) {
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  /// Show installation dialog to guide user
  static void showInstallDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('APK downloaded successfully!'),
            const SizedBox(height: 8),
            const Text('Please install the update manually:'),
            const SizedBox(height: 4),
            Text(
              'File: $filePath',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Version comparison ─────────────────────────────────────────────
  /// Returns true if [remote] is strictly greater than [local].
  /// Supports semver with 1, 2, or 3 segments (1.0 / 1.0.0 / 2.1.3).
  bool _isNewer(String remote, String local) {
    try {
      final r = _parse(remote);
      final l = _parse(local);
      for (int i = 0; i < 3; i++) {
        if (r[i] > l[i]) return true;
        if (r[i] < l[i]) return false;
      }
      return false; // equal
    } catch (_) {
      return false;
    }
  }

  List<int> _parse(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts;
  }
}
