import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF161A22);
  static const surfaceElevated = Color(0xFF1E2330);
  static const border = Color(0xFF252B38);
  static const accent = Color(0xFF4F8EF7);
  static const accentDim = Color(0xFF1A2D54);
  static const buy = Color(0xFF22C55E);
  static const failed = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFEFF2F7);
  static const textSecondary = Color(0xFF8B93A7);
  static const textMuted = Color(0xFF4A5168);
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isSaving = false;
  bool _isFocused = false;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(baseUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showSnack('URL cannot be empty', isError: true);
      setState(() => _isSaving = false);
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showSnack('URL must start with http:// or https://', isError: true);
      setState(() => _isSaving = false);
      return;
    }

    try {
      await ref.read(baseUrlProvider.notifier).updateUrl(url);
      if (mounted) _showSnack('URL saved successfully');
    } catch (e) {
      _showSnack('Failed to save URL: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefault() async {
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);
    try {
      await ref.read(baseUrlProvider.notifier).resetToDefault();
      final defaultUrl = ref.read(baseUrlProvider);
      _urlController.text = defaultUrl;
      if (mounted) _showSnack('Reset to default URL');
    } catch (e) {
      _showSnack('Failed to reset: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? _C.failed : _C.buy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = ref.watch(baseUrlProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUrlSection(currentUrl),
                    const SizedBox(height: 20),
                    _buildActions(),
                    const SizedBox(height: 28),
                    _buildVersionInfo(),
                    _buildMakeByAxon(),
                    // _buildTipCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 8,
        right: 20,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _C.textSecondary,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: _C.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Settings',
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSection(String currentUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(icon: Icons.link_rounded, label: 'API Connection'),
        const SizedBox(height: 12),
        // Current status indicator
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _C.buy,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.buy.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Server',
                      style: TextStyle(
                        color: _C.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentUrl,
                      style: const TextStyle(
                        color: _C.textSecondary,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // URL input
        Focus(
          onFocusChange: (f) => setState(() => _isFocused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: _C.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused ? _C.accent : _C.border,
                width: _isFocused ? 1.5 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: _C.accent.withValues(alpha: 0.12),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: _C.textPrimary, fontSize: 14),
              cursorColor: _C.accent,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'https://your-api-server.com',
                hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
                prefixIcon: Icon(
                  Icons.link_rounded,
                  color: _isFocused ? _C.accent : _C.textMuted,
                  size: 20,
                ),
                suffixIcon: _urlController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _urlController.clear();
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: _C.textMuted,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Save button
        GestureDetector(
          onTap: _isSaving ? null : _saveUrl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              gradient: _isSaving
                  ? null
                  : const LinearGradient(
                      colors: [_C.accent, Color(0xFF7B5CF0)],
                    ),
              color: _isSaving ? _C.surfaceElevated : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isSaving
                  ? []
                  : [
                      BoxShadow(
                        color: _C.accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _C.textSecondary,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isSaving ? 'Saving…' : 'Save URL',
                  style: TextStyle(
                    color: _isSaving ? _C.textSecondary : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reset button
        GestureDetector(
          onTap: _isSaving ? null : _resetToDefault,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: _C.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restore_rounded,
                  color: _isSaving ? _C.textMuted : _C.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reset to Default',
                  style: TextStyle(
                    color: _isSaving ? _C.textMuted : _C.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            // use package_info_plus to get version
            'v${_packageInfo?.version ?? 'NAN'}',
            style: TextStyle(
              color: _C.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakeByAxon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Made with ❤️ by Axon',
            style: TextStyle(
              color: _C.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildTipCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: _C.accentDim,
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: _C.accent.withValues(alpha: 0.25)),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           width: 34,
  //           height: 34,
  //           decoration: BoxDecoration(
  //             color: _C.accent.withValues(alpha: 0.15),
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: const Icon(
  //             Icons.lightbulb_outline_rounded,
  //             color: _C.accent,
  //             size: 17,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'Local Development Tip',
  //                 style: TextStyle(
  //                   color: _C.accent,
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w700,
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 'Use ngrok to expose your local Flask server:\n ngrok http 5000',
  //                 style: TextStyle(
  //                   color: _C.accent.withValues(alpha: 0.75),
  //                   fontSize: 12.5,
  //                   height: 1.5,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _C.textMuted),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _C.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
