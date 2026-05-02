import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// ──────────────────────────────────────────────────────────────────
///  Flask API Integration for App Updates
///  Uses the following endpoints:
///  - GET /update  → Get update info (version, download_url, etc.)
///  - GET /update/download → Download APK file
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

  // Configure your Flask API base URL
  static const String _baseUrl =
      'http://your-server-ip:8080'; // Update this with your server IP

  // ── Check for update ──────────────────────────────────────────────
  /// Returns [UpdateInfo] when an update is available, null otherwise.
  Future<UpdateInfo?> check() async {
    // Only run on Android — iOS uses App Store
    if (!Platform.isAndroid) return null;

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      // Fetch update info from Flask API
      final response = await http
          .get(Uri.parse('$_baseUrl/update'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if update is available
        if (data['has_update'] == true) {
          final latestVersion = data['version'].toString().trim();

          if (_isNewer(latestVersion, currentVersion)) {
            return UpdateInfo(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              forceUpdate: data['force_update'] ?? false,
              releaseNotes:
                  data['release_notes'] ??
                  'Bug fixes and performance improvements.',
              downloadUrl: '$_baseUrl${data['download_url']}',
              fileSize: data['file_size'] ?? 0,
            );
          }
        }
      } else if (response.statusCode == 404) {
        // No APK file available - this is normal
        print('ℹ️ No update available (APK not found on server)');
        return null;
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
