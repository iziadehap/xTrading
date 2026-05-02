import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_service.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF161A22);
  static const surfaceElevated = Color(0xFF1E2330);
  static const border = Color(0xFF252B38);
  static const accent = Color(0xFF4F8EF7);
  static const accentDim = Color(0xFF1A2D54);
  static const buy = Color(0xFF22C55E);
  static const buyDim = Color(0xFF0F2A1A);
  static const failed = Color(0xFFEF4444);
  static const purple = Color(0xFFA855F7);
  static const textPrimary = Color(0xFFEFF2F7);
  static const textSecondary = Color(0xFF8B93A7);
  static const textMuted = Color(0xFF4A5168);
}

/// Shows the update dialog. Returns false if user dismissed (skipped).
/// Call this from your home screen or main after checking for update.
Future<bool> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => _UpdateDialog(info: info),
  );
  return result ?? false;
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      final filePath = await UpdateService.instance.downloadAndInstall(
        info: widget.info,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() => _phase = _Phase.done);
        // Show installation dialog
        UpdateService.showInstallDialog(context, filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.border),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVersionRow(),
                      const SizedBox(height: 16),
                      _buildReleaseNotes(),
                      const SizedBox(height: 20),
                      _buildActionArea(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.accentDim, _C.accent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.accent.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.purple.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.accent, Color(0xFF7B5CF0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _C.accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(
                        color: _C.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.info.forceUpdate
                          ? 'Required update — please install'
                          : 'A new version is ready to install',
                      style: const TextStyle(
                        color: _C.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          _VersionChip(
            label: 'Current',
            version: widget.info.currentVersion,
            color: _C.textMuted,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: _C.textMuted,
          ),
          const SizedBox(width: 8),
          _VersionChip(
            label: 'New',
            version: widget.info.latestVersion,
            color: _C.buy,
            highlighted: true,
          ),
          const Spacer(),
          if (widget.info.forceUpdate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _C.failed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.failed.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: _C.failed),
                  SizedBox(width: 4),
                  Text(
                    'Required',
                    style: TextStyle(
                      color: _C.failed,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes() {
    if (widget.info.releaseNotes.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.article_outlined, size: 13, color: _C.textMuted),
              SizedBox(width: 6),
              Text(
                "WHAT'S NEW",
                style: TextStyle(
                  color: _C.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.info.releaseNotes,
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    switch (_phase) {
      case _Phase.idle:
        return _buildIdleActions();
      case _Phase.downloading:
        return _buildDownloadProgress();
      case _Phase.done:
        return _buildDoneState();
      case _Phase.error:
        return _buildErrorState();
    }
  }

  Widget _buildIdleActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: _startDownload,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.accent, Color(0xFF7B5CF0)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Download & Install',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!widget.info.forceUpdate) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _skip,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _C.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: const Center(
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: _C.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadProgress() {
    final percent = (_progress * 100).toStringAsFixed(0);
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.download_rounded, size: 15, color: _C.accent),
            const SizedBox(width: 6),
            const Text(
              'Downloading…',
              style: TextStyle(color: _C.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: const TextStyle(
                color: _C.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: _C.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(_C.accent),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please keep app open during download',
          style: TextStyle(color: _C.textMuted, fontSize: 11.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoneState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.buyDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.buy.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _C.buy, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Download complete! Follow the system prompt to install.',
                  style: TextStyle(
                    color: _C.buy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.failed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.failed.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _C.failed,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Download failed. Please try again.',
                  style: const TextStyle(color: _C.failed, fontSize: 12.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _startDownload,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.accent, Color(0xFF7B5CF0)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Retry Download',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final String version;
  final Color color;
  final bool highlighted;

  const _VersionChip({
    required this.label,
    required this.version,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.1) : _C.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? color.withValues(alpha: 0.3) : _C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'v$version',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Phase { idle, downloading, done, error }
