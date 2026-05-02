import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signal_model.dart';
import '../providers/signal_provider.dart';

// ── Design Tokens (shared with home screen) ───────────────────────────────────
class _C {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF161A22);
  static const surfaceElevated = Color(0xFF1E2330);
  static const border = Color(0xFF252B38);

  static const accent = Color(0xFF4F8EF7);
  static const buy = Color(0xFF22C55E);
  static const buyDim = Color(0xFF0F2A1A);
  static const wait = Color(0xFFF59E0B);
  static const waitDim = Color(0xFF2A1E0A);
  static const failed = Color(0xFFEF4444);
  static const failedDim = Color(0xFF2A0F0F);
  static const purple = Color(0xFFA855F7);
  static const purpleDim = Color(0xFF1F0F2A);

  static const textPrimary = Color(0xFFEFF2F7);
  static const textSecondary = Color(0xFF8B93A7);
  static const textMuted = Color(0xFF4A5168);
}

class SignalCard extends ConsumerWidget {
  final Signal signal;

  const SignalCard({super.key, required this.signal});

  Color get _signalColor {
    if (signal.isBuy) return _C.buy;
    if (signal.isWait) return _C.wait;
    if (signal.isFailed) return _C.failed;
    return _C.textSecondary;
  }

  Color get _signalDim {
    if (signal.isBuy) return _C.buyDim;
    if (signal.isWait) return _C.waitDim;
    if (signal.isFailed) return _C.failedDim;
    return _C.surfaceElevated;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSignals = ref.watch(savedSignalsProvider);
    final isSaved = savedSignals.any(
      (s) => createSignalId(s) == createSignalId(signal),
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetails(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _signalColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _signalColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Colored top accent bar ─────────────────────────────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _signalColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(ref, isSaved),
                  const SizedBox(height: 10),
                  _buildReason(),
                  if (signal.stopLoss != null || signal.target != null) ...[
                    const SizedBox(height: 10),
                    _buildPriceLevels(),
                  ],
                  const SizedBox(height: 10),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, bool isSaved) {
    return Row(
      children: [
        // Signal emoji badge
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _signalDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _signalColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              signal.signalEmoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Symbol + time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                signal.symbol,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: _C.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    signal.formattedTime,
                    style: const TextStyle(color: _C.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Signal badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _signalDim,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _signalColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            signal.signal,
            style: TextStyle(
              color: _signalColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bookmark
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(savedSignalsProvider.notifier).toggleSave(signal);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSaved ? _C.purpleDim : _C.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSaved ? _C.purple.withValues(alpha: 0.4) : _C.border,
                width: 1,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(isSaved),
                color: isSaved ? _C.purple : _C.textMuted,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReason() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _C.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border, width: 1),
      ),
      child: Text(
        signal.reason,
        style: const TextStyle(
          color: _C.textSecondary,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPriceLevels() {
    return Row(
      children: [
        if (signal.stopLoss != null) ...[
          _PriceChip(
            label: 'SL',
            value: signal.stopLoss!,
            color: _C.failed,
            icon: Icons.arrow_downward_rounded,
          ),
          const SizedBox(width: 8),
        ],
        if (signal.target != null) ...[
          _PriceChip(
            label: 'TP',
            value: signal.target!,
            color: _C.buy,
            icon: Icons.arrow_upward_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    final passedCount = _getPassedConditions();
    return Row(
      children: [
        if (signal.conditionsStatus != null) ...[
          _ConditionsBadge(passed: passedCount, total: 5),
          const SizedBox(width: 8),
        ],
        if (signal.strategyDetails != null) ...[
          _ConfidenceBadge(level: signal.strategyDetails!.confidenceLevel),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        Row(
          children: [
            Text(
              'Details',
              style: TextStyle(
                color: _C.accent.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: _C.accent.withValues(alpha: 0.8),
            ),
          ],
        ),
      ],
    );
  }

  int _getPassedConditions() {
    if (signal.conditionsStatus == null) return 0;
    final c = signal.conditionsStatus!;
    return [
      c.dailyBollinger,
      c.hourlyBollinger,
      c.rsiTrend,
      c.obvTrend,
      c.fibonacci,
    ].where((s) => s == '✅').length;
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignalDetailSheet(signal: signal),
    );
  }
}

// ── Price Chip ─────────────────────────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$label  ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conditions Badge ──────────────────────────────────────────────────────────
class _ConditionsBadge extends StatelessWidget {
  final int passed;
  final int total;

  const _ConditionsBadge({required this.passed, required this.total});

  @override
  Widget build(BuildContext context) {
    final allGood = passed == total;
    final color = allGood ? _C.buy : _C.wait;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allGood ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$passed/$total',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confidence Badge ──────────────────────────────────────────────────────────
class _ConfidenceBadge extends StatelessWidget {
  final String level;

  const _ConfidenceBadge({required this.level});

  Color get _color {
    final l = level.toLowerCase();
    if (l.contains('high') || l.contains('عالي')) return _C.buy;
    if (l.contains('medium') || l.contains('متوسط')) return _C.wait;
    if (l.contains('low') || l.contains('منخفض')) return _C.failed;
    return _C.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              color: _color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Sheet ──────────────────────────────────────────────────────────────
class _SignalDetailSheet extends StatelessWidget {
  final Signal signal;

  const _SignalDetailSheet({required this.signal});

  Color get _signalColor {
    if (signal.isBuy) return _C.buy;
    if (signal.isWait) return _C.wait;
    if (signal.isFailed) return _C.failed;
    return _C.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle + Header (fixed)
            _buildSheetHeader(),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReasonSection(),
                    if (signal.currentPrice != null ||
                        signal.currentRsi != null ||
                        signal.bbPosition != null) ...[
                      const SizedBox(height: 16),
                      _buildTechnicalSection(),
                    ],
                    if (signal.conditionsStatus != null) ...[
                      const SizedBox(height: 16),
                      _buildConditionsSection(),
                    ],
                    if (signal.strategyDetails != null) ...[
                      const SizedBox(height: 16),
                      _buildStrategySection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _signalColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _signalColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    signal.signalEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.symbol,
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${signal.formattedDate}  •  ${signal.formattedTime}',
                      style: const TextStyle(color: _C.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _signalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _signalColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  signal.signal,
                  style: TextStyle(
                    color: _signalColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionLabel(icon: Icons.chat_bubble_outline_rounded, label: 'Reason'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Text(
            signal.reason,
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
        if (signal.stopLoss != null || signal.target != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (signal.stopLoss != null)
                Expanded(
                  child: _LevelCard(
                    label: 'Stop Loss',
                    value: signal.stopLoss!,
                    color: _C.failed,
                    icon: Icons.shield_outlined,
                  ),
                ),
              if (signal.stopLoss != null && signal.target != null)
                const SizedBox(width: 10),
              if (signal.target != null)
                Expanded(
                  child: _LevelCard(
                    label: 'Take Profit',
                    value: signal.target!,
                    color: _C.buy,
                    icon: Icons.flag_outlined,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTechnicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.analytics_outlined, label: 'Technical'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              if (signal.currentPrice != null)
                _TechRow(
                  label: 'Current Price',
                  value: signal.currentPrice!.toStringAsFixed(2),
                  color: _C.accent,
                ),
              if (signal.currentRsi != null) ...[
                const _Divider(),
                _TechRow(
                  label: 'RSI',
                  value: signal.currentRsi!.toStringAsFixed(1),
                  color: _getRsiColor(signal.currentRsi!),
                  suffix: signal.currentRsi! >= 70
                      ? 'Overbought'
                      : signal.currentRsi! <= 30
                      ? 'Oversold'
                      : 'Neutral',
                ),
              ],
              if (signal.bbPosition != null) ...[
                const _Divider(),
                _TechRow(
                  label: 'BB Position',
                  value: '${signal.bbPosition!.toStringAsFixed(1)}%',
                  color: _getBbColor(signal.bbPosition!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionsSection() {
    final c = signal.conditionsStatus!;
    final conditions = [
      ('Daily Bollinger', c.dailyBollinger),
      ('Hourly Bollinger', c.hourlyBollinger),
      ('RSI Trend', c.rsiTrend),
      ('OBV Trend', c.obvTrend),
      ('Fibonacci', c.fibonacci),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.checklist_rounded, label: 'Conditions'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < conditions.length; i++) ...[
                if (i > 0) const _Divider(),
                _ConditionRow(
                  label: conditions[i].$1,
                  status: conditions[i].$2,
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: c.allPassed
                      ? _C.buy.withValues(alpha: 0.1)
                      : _C.wait.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: c.allPassed
                        ? _C.buy.withValues(alpha: 0.3)
                        : _C.wait.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  c.allPassed
                      ? '✅  All Conditions Passed'
                      : '⚠️  Some Conditions Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.allPassed ? _C.buy : _C.wait,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategySection() {
    final s = signal.strategyDetails!;
    final confColor = s.confidenceColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.track_changes_rounded, label: 'Strategy'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              if (s.entryPrice != null) ...[
                _TechRow(
                  label: 'Entry Price',
                  value: s.entryPrice!.toStringAsFixed(2),
                  color: _C.accent,
                ),
                const _Divider(),
              ],
              if (s.riskRewardRatio != null) ...[
                _TechRow(
                  label: 'Risk / Reward',
                  value: '1 : ${s.riskRewardRatio!.toStringAsFixed(2)}',
                  color: _C.purple,
                ),
                const _Divider(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Confidence',
                    style: TextStyle(color: _C.textSecondary, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: confColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: confColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: confColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.confidenceLevel,
                          style: TextStyle(
                            color: confColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRsiColor(double rsi) {
    if (rsi >= 70) return _C.failed;
    if (rsi <= 30) return _C.buy;
    return _C.wait;
  }

  Color _getBbColor(double pos) {
    if (pos >= 80) return _C.failed;
    if (pos <= 20) return _C.buy;
    return _C.wait;
  }
}

// ── Shared Sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _C.textMuted),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: _C.border, height: 1),
    );
  }
}

class _TechRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? suffix;

  const _TechRow({
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _C.textSecondary, fontSize: 13),
        ),
        Row(
          children: [
            if (suffix != null) ...[
              Text(
                suffix!,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final String status;

  const _ConditionRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final passed = status == '✅';
    final color = passed ? _C.buy : _C.failed;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _C.textSecondary, fontSize: 13),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_rounded : Icons.close_rounded,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                passed ? 'Passed' : 'Failed',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _LevelCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
