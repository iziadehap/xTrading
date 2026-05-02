import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:android_intent_plus/flag.dart';
import 'package:open_filex/open_filex.dart';

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

class DownloadState {
  final String version;
  final String filePath;
  final double progress;
  final bool isCompleted;
  final bool isFailed;
  final String? errorMessage;

  const DownloadState({
    required this.version,
    required this.filePath,
    required this.progress,
    required this.isCompleted,
    required this.isFailed,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'filePath': filePath,
      'progress': progress,
      'isCompleted': isCompleted,
      'isFailed': isFailed,
      'errorMessage': errorMessage,
    };
  }

  factory DownloadState.fromJson(Map<String, dynamic> json) {
    return DownloadState(
      version: json['version'] ?? '',
      filePath: json['filePath'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
      isFailed: json['isFailed'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  DownloadState copyWith({
    String? version,
    String? filePath,
    double? progress,
    bool? isCompleted,
    bool? isFailed,
    String? errorMessage,
  }) {
    return DownloadState(
      version: version ?? this.version,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
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

  // SharedPreferences keys
  static const String _downloadStateKey = 'download_state';

  // Get current download state
  Future<DownloadState?> getDownloadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_downloadStateKey);
      if (json != null) {
        final state = DownloadState.fromJson(jsonDecode(json));
        // Check if file still exists
        final file = File(state.filePath);
        if (await file.exists()) {
          return state;
        } else {
          // File doesn't exist, clear the state
          await clearDownloadState();
        }
      }
    } catch (e) {
      print('⚠️ Error getting download state: $e');
    }
    return null;
  }

  // Save download state
  Future<void> saveDownloadState(DownloadState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadStateKey, jsonEncode(state.toJson()));
    } catch (e) {
      print('⚠️ Error saving download state: $e');
    }
  }

  // Clear download state
  Future<void> clearDownloadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadStateKey);
    } catch (e) {
      print('⚠️ Error clearing download state: $e');
    }
  }

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
  /// Supports resume functionality and persistent state.
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

      // Check for existing download state
      final existingState = await getDownloadState();

      // Initialize download state
      final downloadState = DownloadState(
        version: info.latestVersion,
        filePath: filePath,
        progress: existingState?.progress ?? 0.0,
        isCompleted: false,
        isFailed: false,
      );

      await saveDownloadState(downloadState);

      // Check if file already exists and get its size for resume
      int existingBytes = 0;
      if (await file.exists()) {
        existingBytes = await file.length();
        if (existingBytes > 0) {
          print('📥 Resuming download from ${existingBytes} bytes');
        }
      }

      // Download APK with resume support using HTTP Range requests
      final request = http.Request('GET', Uri.parse(info.downloadUrl));

      // Add Range header for resume support
      if (existingBytes > 0) {
        request.headers.addAll({'Range': 'bytes=$existingBytes-'});
      }

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 206 && existingBytes > 0) {
        // Server doesn't support range requests, start fresh
        print('⚠️ Server doesnt support resume, starting fresh download');
        existingBytes = 0;
        if (await file.exists()) {
          await file.delete();
        }
        final freshResponse = await http.get(Uri.parse(info.downloadUrl));
        if (freshResponse.statusCode != 200) {
          throw Exception(
            'Failed to start download: ${freshResponse.statusCode}',
          );
        }
        await file.writeAsBytes(freshResponse.bodyBytes);
        onProgress(1.0);
      } else {
        // Append to existing file
        final contentLength = streamedResponse.contentLength ?? 0;
        final totalLength = existingBytes + contentLength;

        final sink = file.openWrite(mode: FileMode.append);
        int downloadedBytes = existingBytes;

        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalLength > 0) {
            final progress = downloadedBytes / totalLength;
            onProgress(progress);

            // Update download state periodically
            await saveDownloadState(downloadState.copyWith(progress: progress));
          }
        }

        await sink.close();
        onProgress(1.0);
      }

      // Mark download as completed
      final completedState = downloadState.copyWith(
        progress: 1.0,
        isCompleted: true,
      );
      await saveDownloadState(completedState);

      // Return file path for manual installation
      if (await file.exists()) {
        return filePath;
      } else {
        throw Exception('Downloaded file not found at $filePath');
      }
    } catch (e) {
      // Mark download as failed
      final currentState = await getDownloadState();
      if (currentState != null) {
        await saveDownloadState(
          currentState.copyWith(isFailed: true, errorMessage: e.toString()),
        );
      }
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  /// Open downloaded APK file for installation
  Future<bool> openApkFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ File not found: $filePath');
        return false;
      }

      // On Android, use open_filex to directly open the APK file
      if (Platform.isAndroid) {
        final result = await OpenFilex.open(filePath);

        if (result.type == ResultType.done) {
          print('📱 APK opened successfully for installation: $filePath');
          return true;
        } else if (result.type == ResultType.error) {
          print('❌ Failed to open APK: ${result.message}');
          return false;
        } else {
          print('❌ Failed to open APK: ${result.message}');
          return false;
        }
      } else {
        print('⚠️ APK installation is only supported on Android');
        return false;
      }
    } catch (e) {
      print('❌ Failed to open APK file: $e');
      // Fallback to manual installation guidance
      print(
        '💡 Please navigate to the file and install it manually: $filePath',
      );
      return false;
    }
  }

  /// Check if there's a completed download available
  Future<DownloadState?> getCompletedDownload() async {
    final state = await getDownloadState();
    if (state != null && state.isCompleted) {
      final file = File(state.filePath);
      if (await file.exists()) {
        return state;
      } else {
        // File doesn't exist, clear the state
        await clearDownloadState();
      }
    }
    return null;
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
            const Text('Tap Install to open the APK file:'),
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
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await instance.openApkFile(filePath);
              if (!success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to open APK. Please install manually.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Install'),
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
