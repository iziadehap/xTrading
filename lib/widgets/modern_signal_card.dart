import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signal_model.dart';

class ModernSignalCard extends ConsumerWidget {
  final Signal signal;

  const ModernSignalCard({super.key, required this.signal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSignalDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref),
                const SizedBox(height: 12),
                _buildMainInfo(),
                const SizedBox(height: 12),
                _buildPriceInfo(),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSignalColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                signal.signalEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.symbol,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  signal.formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getSignalColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            signal.signal,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getSignalColor(),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            signal.reason,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          if (signal.strategyDetails != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: signal.strategyDetails!.confidenceColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Confidence: ${signal.strategyDetails!.confidenceLevel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: signal.strategyDetails!.confidenceColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      children: [
        if (signal.currentPrice != null)
          _buildPriceChip('Current', signal.currentPrice!, Colors.blue),
        if (signal.stopLoss != null)
          _buildPriceChip('SL', signal.stopLoss!, Colors.red),
        if (signal.target != null)
          _buildPriceChip('TP', signal.target!, Colors.green),
        if (signal.currentRsi != null)
          _buildPriceChip(
            'RSI',
            signal.currentRsi!,
            _getRsiColor(signal.currentRsi!),
          ),
      ],
    );
  }

  Widget _buildPriceChip(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label: ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (signal.conditionsStatus != null)
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: _getConditionsColor()),
              const SizedBox(width: 4),
              Text(
                '${_getPassedConditions()}/5 Conditions',
                style: TextStyle(
                  fontSize: 11,
                  color: _getConditionsColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        Text(
          'Tap for details →',
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSignalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (signal.currentRsi != null ||
                          signal.bbPosition != null)
                        _buildTechnicalIndicators(),
                      if (signal.conditionsStatus != null)
                        _buildConditionsStatus(),
                      if (signal.strategyDetails != null)
                        _buildStrategyDetails(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${signal.signalEmoji} ${signal.symbol}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getSignalColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            signal.signal,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getSignalColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalIndicators() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Technical Indicators',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (signal.currentRsi != null)
            _buildIndicatorRow(
              'RSI',
              signal.currentRsi!,
              _getRsiColor(signal.currentRsi!),
            ),
          if (signal.bbPosition != null)
            _buildIndicatorRow(
              'BB Position',
              signal.bbPosition!,
              _getBbPositionColor(signal.bbPosition!),
            ),
        ],
      ),
    );
  }

  Widget _buildConditionsStatus() {
    final conditions = signal.conditionsStatus!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔍 Conditions Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 12),
          _buildConditionChip('Daily Bollinger', conditions.dailyBollinger),
          _buildConditionChip('Hourly Bollinger', conditions.hourlyBollinger),
          _buildConditionChip('RSI Trend', conditions.rsiTrend),
          _buildConditionChip('OBV Trend', conditions.obvTrend),
          _buildConditionChip('Fibonacci', conditions.fibonacci),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: conditions.allPassed
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              conditions.allPassed
                  ? '✅ All Conditions Passed'
                  : '❌ Some Conditions Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: conditions.allPassed
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyDetails() {
    final strategy = signal.strategyDetails!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Strategy Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (strategy.entryPrice != null)
            _buildIndicatorRow(
              'Entry Price',
              strategy.entryPrice!,
              Colors.purple,
            ),
          if (strategy.riskRewardRatio != null)
            _buildIndicatorRow(
              'Risk/Reward',
              strategy.riskRewardRatio!,
              Colors.purple,
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: strategy.confidenceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Confidence Level: ${strategy.confidenceLevel}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: strategy.confidenceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toStringAsFixed(2),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionChip(String label, String status) {
    final isPassed = status == '✅';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPassed ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor() {
    if (signal.isBuy) return Colors.green;
    if (signal.isWait) return Colors.orange;
    if (signal.isFailed) return Colors.red;
    return Colors.grey;
  }

  Color _getRsiColor(double rsi) {
    if (rsi >= 70) return Colors.red;
    if (rsi <= 30) return Colors.green;
    return Colors.orange;
  }

  Color _getBbPositionColor(double position) {
    if (position >= 80) return Colors.red;
    if (position <= 20) return Colors.green;
    return Colors.orange;
  }

  Color _getConditionsColor() {
    if (signal.conditionsStatus == null) return Colors.grey;
    return signal.conditionsStatus!.allPassed ? Colors.green : Colors.orange;
  }

  int _getPassedConditions() {
    if (signal.conditionsStatus == null) return 0;
    final conditions = signal.conditionsStatus!;
    int count = 0;
    if (conditions.dailyBollinger == '✅') count++;
    if (conditions.hourlyBollinger == '✅') count++;
    if (conditions.rsiTrend == '✅') count++;
    if (conditions.obvTrend == '✅') count++;
    if (conditions.fibonacci == '✅') count++;
    return count;
  }
}
