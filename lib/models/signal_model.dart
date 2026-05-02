import 'package:flutter/material.dart';

class Signal {
  final String symbol;
  final String signal;
  final String reason;
  final double? stopLoss;
  final double? target;
  final String time;
  final double? currentPrice;
  final double? currentRsi;
  final double? bbPosition;
  final double? bbUpper;
  final double? bbMiddle;
  final double? bbLower;
  final ConditionsStatus? conditionsStatus;
  final StrategyDetails? strategyDetails;

  Signal({
    required this.symbol,
    required this.signal,
    required this.reason,
    this.stopLoss,
    this.target,
    required this.time,
    this.currentPrice,
    this.currentRsi,
    this.bbPosition,
    this.bbUpper,
    this.bbMiddle,
    this.bbLower,
    this.conditionsStatus,
    this.strategyDetails,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      symbol: json['symbol'] ?? '',
      signal: json['signal'] ?? '',
      reason: json['reason'] ?? '',
      stopLoss: json['stop_loss'] != null
          ? double.tryParse(json['stop_loss'].toString())
          : null,
      target: json['target'] != null
          ? double.tryParse(json['target'].toString())
          : null,
      time: json['time'] ?? '',
      currentPrice: json['current_price'] != null
          ? double.tryParse(json['current_price'].toString())
          : null,
      currentRsi: json['current_rsi'] != null
          ? double.tryParse(json['current_rsi'].toString())
          : null,
      bbPosition: json['bb_position'] != null
          ? double.tryParse(json['bb_position'].toString())
          : null,
      bbUpper: json['bb_upper'] != null
          ? double.tryParse(json['bb_upper'].toString())
          : null,
      bbMiddle: json['bb_middle'] != null
          ? double.tryParse(json['bb_middle'].toString())
          : null,
      bbLower: json['bb_lower'] != null
          ? double.tryParse(json['bb_lower'].toString())
          : null,
      conditionsStatus: json['conditions_status'] != null
          ? ConditionsStatus.fromJson(json['conditions_status'])
          : null,
      strategyDetails: json['strategy_details'] != null
          ? StrategyDetails.fromJson(json['strategy_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'signal': signal,
      'reason': reason,
      'stop_loss': stopLoss,
      'target': target,
      'time': time,
      'current_price': currentPrice,
      'current_rsi': currentRsi,
      'bb_position': bbPosition,
      'bb_upper': bbUpper,
      'bb_middle': bbMiddle,
      'bb_lower': bbLower,
      'conditions_status': conditionsStatus?.toJson(),
      'strategy_details': strategyDetails?.toJson(),
    };
  }

  bool get isBuy => signal == 'BUY';
  bool get isWait => signal == 'WAIT';
  bool get isFailed => signal == 'NO_SIGNAL';

  String get signalEmoji {
    if (isBuy) return '🟢';
    if (isWait) return '⏳';
    if (isFailed) return '🔴';
    return '⚪';
  }

  String get formattedTime {
    if (time.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(time);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time;
    }
  }

  String get formattedDate {
    if (time.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(time);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return time;
    }
  }
}

class ConditionsStatus {
  final String dailyBollinger;
  final String hourlyBollinger;
  final String rsiTrend;
  final String obvTrend;
  final String fibonacci;

  ConditionsStatus({
    required this.dailyBollinger,
    required this.hourlyBollinger,
    required this.rsiTrend,
    required this.obvTrend,
    required this.fibonacci,
  });

  factory ConditionsStatus.fromJson(Map<String, dynamic> json) {
    return ConditionsStatus(
      dailyBollinger: json['daily_bollinger'] ?? '',
      hourlyBollinger: json['hourly_bollinger'] ?? '',
      rsiTrend: json['rsi_trend'] ?? '',
      obvTrend: json['obv_trend'] ?? '',
      fibonacci: json['fibonacci'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_bollinger': dailyBollinger,
      'hourly_bollinger': hourlyBollinger,
      'rsi_trend': rsiTrend,
      'obv_trend': obvTrend,
      'fibonacci': fibonacci,
    };
  }

  bool get allPassed =>
      dailyBollinger == '✅' &&
      hourlyBollinger == '✅' &&
      rsiTrend == '✅' &&
      obvTrend == '✅' &&
      fibonacci == '✅';
}

class StrategyDetails {
  final double? entryPrice;
  final double? riskRewardRatio;
  final String confidenceLevel;

  StrategyDetails({
    this.entryPrice,
    this.riskRewardRatio,
    required this.confidenceLevel,
  });

  factory StrategyDetails.fromJson(Map<String, dynamic> json) {
    return StrategyDetails(
      entryPrice: json['entry_price'] != null
          ? double.tryParse(json['entry_price'].toString())
          : null,
      riskRewardRatio: json['risk_reward_ratio'] != null
          ? double.tryParse(json['risk_reward_ratio'].toString())
          : null,
      confidenceLevel: json['confidence_level'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_price': entryPrice,
      'risk_reward_ratio': riskRewardRatio,
      'confidence_level': confidenceLevel,
    };
  }

  Color get confidenceColor {
    switch (confidenceLevel.toLowerCase()) {
      case 'عالي':
      case 'high':
        return Colors.green;
      case 'متوسط':
      case 'medium':
        return Colors.orange;
      case 'منخفض':
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
