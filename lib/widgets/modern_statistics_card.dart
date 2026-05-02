import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signal_provider.dart';
import '../models/signal_model.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  // static const surface = Color(0xFF161A22);
  static const surfaceElevated = Color(0xFF1E2330);
  static const border = Color(0xFF252B38);
  static const accent = Color(0xFF4F8EF7);
  static const buy = Color(0xFF22C55E);
  static const wait = Color(0xFFF59E0B);
  static const failed = Color(0xFFEF4444);
  // static const purple = Color(0xFFA855F7);
  // static const textPrimary = Color(0xFFEFF2F7);
  // static const textMuted = Color(0xFF4A5168);
}

class ModernStatisticsCard extends ConsumerWidget {
  const ModernStatisticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalsAsync = ref.watch(allSignalsProvider);

    if (signalsAsync is AsyncLoading) {
      return _buildSkeleton();
    }

    if (signalsAsync is AsyncError) {
      return const SizedBox.shrink();
    }

    if (signalsAsync is AsyncData) {
      final stats = _calculateStatistics(signalsAsync.value!);
      return _buildStats(stats);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              height: 68,
              decoration: BoxDecoration(
                color: _C.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(SignalStatistics stats) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          _StatTile(
            label: 'Total',
            count: stats.total,
            color: _C.accent,
            icon: Icons.signal_cellular_alt_rounded,
          ),
          const SizedBox(width: 8),
          _StatTile(
            label: 'Buy',
            count: stats.buyCount,
            color: _C.buy,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(width: 8),
          _StatTile(
            label: 'Wait',
            count: stats.waitCount,
            color: _C.wait,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 8),
          _StatTile(
            label: 'Failed',
            count: stats.failedCount,
            color: _C.failed,
            icon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 5),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Statistics Model ──────────────────────────────────────────────────────────
class SignalStatistics {
  final int total;
  final int buyCount;
  final int waitCount;
  final int failedCount;
  final int highConfidence;
  final int mediumConfidence;
  final int lowConfidence;
  final int allConditionsPassed;
  final int someConditionsFailed;
  final int noConditionData;

  SignalStatistics({
    required this.total,
    required this.buyCount,
    required this.waitCount,
    required this.failedCount,
    required this.highConfidence,
    required this.mediumConfidence,
    required this.lowConfidence,
    required this.allConditionsPassed,
    required this.someConditionsFailed,
    required this.noConditionData,
  });
}

SignalStatistics _calculateStatistics(List<Signal> signals) {
  int buyCount = 0;
  int waitCount = 0;
  int failedCount = 0;
  int highConfidence = 0;
  int mediumConfidence = 0;
  int lowConfidence = 0;
  int allConditionsPassed = 0;
  int someConditionsFailed = 0;
  int noConditionData = 0;

  for (final signal in signals) {
    if (signal.isBuy) buyCount++;
    if (signal.isWait) waitCount++;
    if (signal.isFailed) failedCount++;

    if (signal.strategyDetails != null) {
      final confidence = signal.strategyDetails!.confidenceLevel.toLowerCase();
      if (confidence.contains('عالي') || confidence.contains('high')) {
        highConfidence++;
      } else if (confidence.contains('متوسط') || confidence.contains('medium')) {
        mediumConfidence++;
      } else if (confidence.contains('منخفض') || confidence.contains('low')) {
        lowConfidence++;
      }
    }

    if (signal.conditionsStatus != null) {
      if (signal.conditionsStatus!.allPassed) {
        allConditionsPassed++;
      } else {
        someConditionsFailed++;
      }
    } else {
      noConditionData++;
    }
  }

  return SignalStatistics(
    total: signals.length,
    buyCount: buyCount,
    waitCount: waitCount,
    failedCount: failedCount,
    highConfidence: highConfidence,
    mediumConfidence: mediumConfidence,
    lowConfidence: lowConfidence,
    allConditionsPassed: allConditionsPassed,
    someConditionsFailed: someConditionsFailed,
    noConditionData: noConditionData,
  );
}