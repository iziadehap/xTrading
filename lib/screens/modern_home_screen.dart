import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signal_provider.dart';
import '../models/signal_model.dart';
import '../widgets/signal_card.dart';
import '../widgets/modern_statistics_card.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';
import 'saved_signals_screen.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF161A22);
  static const surfaceElevated = Color(0xFF1E2330);
  static const border = Color(0xFF252B38);

  static const accent = Color(0xFF4F8EF7);
  static const accentDim = Color(0xFF1A2D54);

  static const buy = Color(0xFF22C55E);
  static const buyDim = Color(0xFF0F2A1A);
  static const wait = Color(0xFFF59E0B);
  static const waitDim = Color(0xFF2A1E0A);
  static const failed = Color(0xFFEF4444);
  static const failedDim = Color(0xFF2A0F0F);
  static const latest = Color(0xFFA855F7);
  static const latestDim = Color(0xFF1F0F2A);

  static const textPrimary = Color(0xFFEFF2F7);
  static const textSecondary = Color(0xFF8B93A7);
  static const textMuted = Color(0xFF4A5168);
}

// ── Tab Data ─────────────────────────────────────────────────────────────────
class _TabItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color dimColor;
  _TabItem(this.label, this.icon, this.color, this.dimColor);
}

final _tabs = [
  _TabItem(
    'All',
    Icons.grid_view_rounded,
    _AppColors.accent,
    _AppColors.accentDim,
  ),
  _TabItem('Buy', Icons.trending_up_rounded, _AppColors.buy, _AppColors.buyDim),
  _TabItem('Wait', Icons.schedule_rounded, _AppColors.wait, _AppColors.waitDim),
  _TabItem(
    'Failed',
    Icons.cancel_rounded,
    _AppColors.failed,
    _AppColors.failedDim,
  ),
  _TabItem(
    'Latest',
    Icons.bolt_rounded,
    _AppColors.latest,
    _AppColors.latestDim,
  ),
  _TabItem(
    'Saved',
    Icons.bookmark_rounded,
    Colors.purple,
    Colors.purple.withValues(alpha: 0.2),
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
          ref.read(selectedTabProvider.notifier).state = _tabController.index;
        }
      });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Check for updates after UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesAndShowDialog();
    });
  }

  Future<void> _checkForUpdatesAndShowDialog() async {
    try {
      final updateInfo = await UpdateService.instance.check();
      if (updateInfo != null && mounted) {
        final shouldUpdate = await showUpdateDialog(context, updateInfo);
        if (shouldUpdate) {
          // Update was initiated, dialog will handle download
        }
      }
    } catch (e) {
      print('❌ Failed to check for updates: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: _AppColors.bg,
          body: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: 4),
                _buildStatsRow(),
                const SizedBox(height: 12),
                _buildTabBar(),
                const SizedBox(height: 4),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        border: Border(bottom: BorderSide(color: _AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo + Title
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_AppColors.accent, Color(0xFF7B5CF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.candlestick_chart_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trading Signals',
                  style: TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final connectionStatus = ref.watch(
                      connectionStatusProvider,
                    );
                    final baseUrl = ref.watch(baseUrlProvider);

                    Color statusColor;
                    String statusText;
                    IconData statusIcon;

                    switch (connectionStatus) {
                      case ConnectionStatus.connected:
                        statusColor = _AppColors.buy;
                        statusText = 'Live';
                        statusIcon = Icons.circle;
                        break;
                      case ConnectionStatus.connecting:
                        statusColor = Colors.orange;
                        statusText = 'Connecting';
                        statusIcon = Icons.hourglass_empty;
                        break;
                      case ConnectionStatus.disconnected:
                        statusColor = _AppColors.failed;
                        statusText = 'Offline';
                        statusIcon = Icons.circle;
                        break;
                      case ConnectionStatus.unknown:
                        statusColor = Colors.grey;
                        statusText = 'Unknown';
                        statusIcon = Icons.help_outline;
                        break;
                    }

                    return Row(
                      children: [
                        Icon(statusIcon, size: 8, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          '$statusText • ${_getShortUrl(baseUrl)}',
                          style: const TextStyle(
                            color: _AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Settings button
          _IconBtn(
            icon: Icons.tune_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSearchActive ? _AppColors.accent : _AppColors.border,
          width: _isSearchActive ? 1.5 : 1,
        ),
        boxShadow: _isSearchActive
            ? [
                BoxShadow(
                  color: _AppColors.accent.withOpacity(0.15),
                  blurRadius: 12,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14),
        cursorColor: _AppColors.accent,
        onChanged: (q) => setState(() => _searchQuery = q),
        onTap: () => setState(() => _isSearchActive = true),
        onTapOutside: (_) => setState(() => _isSearchActive = false),
        decoration: InputDecoration(
          hintText: 'Search symbol, signal, reason…',
          hintStyle: const TextStyle(color: _AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isSearchActive ? _AppColors.accent : _AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: _AppColors.textMuted,
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
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ModernStatisticsCard(),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final tab = _tabs[i];
          final selected = _tabController.index == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _tabController.animateTo(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? tab.dimColor : _AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? tab.color : _AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 15,
                    color: selected ? tab.color : _AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: selected ? tab.color : _AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab Content ────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    final providers = [
      allSignalsProvider,
      buySignalsProvider,
      waitSignalsProvider,
      failedSignalsProvider,
      latestSignalsProvider,
      savedSignalsListProvider,
    ];

    final emptyMessages = [
      'No signals available',
      'No buy signals yet',
      'No wait signals',
      'No failed signals',
      'No latest signals',
      'No saved signals yet',
    ];

    return TabBarView(
      controller: _tabController,
      children: List.generate(
        _tabs.length,
        (i) => _buildSignalsListWithProvider(providers[i], emptyMessages[i]),
      ),
    );
  }

  // ── Signal List ────────────────────────────────────────────────────────────
  Widget _buildSignalsListWithProvider(provider, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      color: _AppColors.accent,
      backgroundColor: _AppColors.surfaceElevated,
      child: Consumer(
        builder: (context, ref, _) {
          final signalsAsync = ref.watch(provider);

          // Use pattern matching for Riverpod 2.x
          if (signalsAsync is AsyncLoading) {
            return _buildLoading();
          }

          if (signalsAsync is AsyncError) {
            return _buildError(signalsAsync.error, provider);
          }

          if (signalsAsync is AsyncData) {
            final filtered = _filterSignals(signalsAsync.value!);
            if (filtered.isEmpty) return _buildEmptyState(emptyMessage);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SignalCard(signal: filtered[index]),
                );
              },
            );
          }

          return _buildLoading();
        },
      ),
    );
  }

  // ── States ─────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                _AppColors.accent,
              ),
              backgroundColor: _AppColors.surfaceElevated,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading signals…',
            style: TextStyle(color: _AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object err, dynamic provider) {
    String errorMessage = err.toString();
    String title = 'Connection Error';
    IconData icon = Icons.wifi_off_rounded;

    // Customize error message based on type
    if (errorMessage.contains('Unable to connect to server')) {
      title = 'Server Unreachable';
      icon = Icons.cloud_off_rounded;
    } else if (errorMessage.contains('timed out')) {
      title = 'Request Timeout';
      icon = Icons.access_time_rounded;
    } else if (errorMessage.contains('API endpoint not found')) {
      title = 'API Not Found';
      icon = Icons.api_rounded;
    } else if (errorMessage.contains('temporarily unavailable')) {
      title = 'Server Busy';
      icon = Icons.sync_problem_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _AppColors.failedDim,
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.failed.withOpacity(0.3)),
              ),
              child: Icon(icon, color: _AppColors.failed, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: _AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PillButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  color: _AppColors.failed,
                  onTap: () => ref.invalidate(provider),
                ),
                const SizedBox(width: 12),
                _PillButton(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  color: _AppColors.accent,
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: _AppColors.border),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: _AppColors.textMuted,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: _AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pull down to refresh',
            style: TextStyle(color: _AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Saved signals mini FAB
        Consumer(
          builder: (context, ref, _) {
            final savedSignals = ref.watch(savedSignalsProvider);
            return _MiniFab(
              icon: Icons.bookmark_rounded,
              color: Colors.purple.withOpacity(0.2),
              iconColor: Colors.purple,
              badge: savedSignals.length.toString(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedSignalsScreen()),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),
        // Filter mini FAB
        _MiniFab(
          icon: Icons.filter_list_rounded,
          color: _AppColors.surfaceElevated,
          iconColor: _AppColors.textSecondary,
          onTap: _showFilterDialog,
        ),
        const SizedBox(height: 10),
        // Refresh main FAB
        GestureDetector(
          onTap: _refreshAllData,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_AppColors.accent, Color(0xFF7B5CF0)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _AppColors.accent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // ── Filter Dialog ──────────────────────────────────────────────────────────
  void _showFilterDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: _AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FilterSheet(),
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────────────
  void _refreshAllData() {
    HapticFeedback.mediumImpact();
    ref.invalidate(allSignalsProvider);
    ref.invalidate(buySignalsProvider);
    ref.invalidate(waitSignalsProvider);
    ref.invalidate(failedSignalsProvider);
    ref.invalidate(latestSignalsProvider);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Data refreshed'),
            ],
          ),
          backgroundColor: _AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<Signal> _filterSignals(List<Signal> signals) {
    if (_searchQuery.isEmpty) return signals;
    final q = _searchQuery.toLowerCase();
    return signals
        .where(
          (s) =>
              s.symbol.toLowerCase().contains(q) ||
              s.signal.toLowerCase().contains(q) ||
              s.reason.toLowerCase().contains(q),
        )
        .toList();
  }

  String _getShortUrl(String url) =>
      url.length > 28 ? '${url.substring(0, 25)}…' : url;
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Icon(icon, color: _AppColors.textSecondary, size: 20),
      ),
    );
  }
}

class _MiniFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  const _MiniFab({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          if (badge != null && badge != '0')
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _AppColors.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  bool _stopLoss = false;
  bool _target = false;
  bool _highConfidence = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Filter Signals',
              style: TextStyle(
                color: _AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FilterTile(
            icon: Icons.security_rounded,
            iconColor: _AppColors.buy,
            label: 'With Stop Loss',
            subtitle: 'Show only risk-managed signals',
            value: _stopLoss,
            onChanged: (v) => setState(() => _stopLoss = v),
          ),
          _FilterTile(
            icon: Icons.flag_rounded,
            iconColor: _AppColors.accent,
            label: 'With Target Price',
            subtitle: 'Show only signals with clear targets',
            value: _target,
            onChanged: (v) => setState(() => _target = v),
          ),
          _FilterTile(
            icon: Icons.verified_rounded,
            iconColor: _AppColors.latest,
            label: 'High Confidence',
            subtitle: 'Top-rated signals only',
            value: _highConfidence,
            onChanged: (v) => setState(() => _highConfidence = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _stopLoss = false;
                    _target = false;
                    _highConfidence = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: _AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_AppColors.accent, Color(0xFF7B5CF0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? iconColor.withOpacity(0.08)
              : _AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? iconColor.withOpacity(0.4) : _AppColors.border,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: value
                          ? _AppColors.textPrimary
                          : _AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
              activeTrackColor: iconColor.withOpacity(0.25),
              inactiveThumbColor: _AppColors.textMuted,
              inactiveTrackColor: _AppColors.border,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
