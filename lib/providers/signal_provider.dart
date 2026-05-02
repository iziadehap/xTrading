import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/signal_model.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

// API Service Provider - auto-updates when base URL changes
final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  return ApiService(baseUrl: baseUrl);
});

// All Signals Provider
final allSignalsProvider = FutureProvider<List<Signal>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchAllSignals();
});

// Buy Signals Provider
final buySignalsProvider = FutureProvider<List<Signal>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchBuySignals();
});

// Wait Signals Provider
final waitSignalsProvider = FutureProvider<List<Signal>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchWaitSignals();
});

// Failed Signals Provider
final failedSignalsProvider = FutureProvider<List<Signal>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchFailedSignals();
});

// Latest Signals Provider
final latestSignalsProvider = FutureProvider<List<Signal>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchLatestSignals();
});

// Selected Tab Index Provider
final selectedTabProvider = StateProvider<int>((ref) => 0);

// Signal Statistics Provider
final signalStatsProvider = Provider<Map<String, int>>((ref) {
  final signalsAsync = ref.watch(allSignalsProvider);

  // Use pattern matching for Riverpod 2.x
  if (signalsAsync is AsyncLoading) {
    return {'total': 0, 'buy': 0, 'wait': 0, 'failed': 0};
  }

  if (signalsAsync is AsyncError) {
    return {'total': 0, 'buy': 0, 'wait': 0, 'failed': 0};
  }

  if (signalsAsync is AsyncData) {
    final signals = signalsAsync.value!;
    final buyCount = signals.where((s) => s.isBuy).length;
    final waitCount = signals.where((s) => s.isWait).length;
    final failedCount = signals.where((s) => s.isFailed).length;

    return {
      'total': signals.length,
      'buy': buyCount,
      'wait': waitCount,
      'failed': failedCount,
    };
  }

  return {'total': 0, 'buy': 0, 'wait': 0, 'failed': 0};
});

// Connection Status Provider
final connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final signalsAsync = ref.watch(allSignalsProvider);

  if (signalsAsync is AsyncLoading) {
    return ConnectionStatus.connecting;
  }

  if (signalsAsync is AsyncError) {
    return ConnectionStatus.disconnected;
  }

  if (signalsAsync is AsyncData) {
    return ConnectionStatus.connected;
  }

  return ConnectionStatus.unknown;
});

enum ConnectionStatus { connected, connecting, disconnected, unknown }

// Saved Signals Provider
class SavedSignalsNotifier extends StateNotifier<List<Signal>> {
  static const String _savedSignalsKey = 'saved_signals_json';
  SharedPreferences? _prefs;

  SavedSignalsNotifier() : super([]) {
    _loadSavedSignals();
  }

  Future<void> _loadSavedSignals() async {
    _prefs ??= await SharedPreferences.getInstance();
    final savedSignalsJson = _prefs!.getString(_savedSignalsKey);
    if (savedSignalsJson != null) {
      try {
        final savedSignalsList = json.decode(savedSignalsJson) as List<dynamic>;
        state = savedSignalsList
            .map((json) => Signal.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error loading saved signals: $e');
        state = [];
      }
    }
  }

  Future<void> _saveToPrefs() async {
    if (_prefs != null) {
      final signalsJson = state.map((signal) => signal.toJson()).toList();
      await _prefs!.setString(_savedSignalsKey, json.encode(signalsJson));
    }
  }

  Future<void> toggleSave(Signal signal) async {
    final signalId = createSignalId(signal);
    final existingIndex = state.indexWhere(
      (s) => createSignalId(s) == signalId,
    );

    if (existingIndex != -1) {
      // Remove signal
      state = [...state]..removeAt(existingIndex);
    } else {
      // Add signal
      state = [...state, signal];
    }
    await _saveToPrefs();
  }

  bool isSaved(String signalId) {
    return state.any((signal) => createSignalId(signal) == signalId);
  }

  Future<void> clearAll() async {
    state = [];
    await _saveToPrefs();
  }

  Future<void> removeSignal(String signalId) async {
    state = state
        .where((signal) => createSignalId(signal) != signalId)
        .toList();
    await _saveToPrefs();
  }
}

final savedSignalsProvider =
    StateNotifierProvider<SavedSignalsNotifier, List<Signal>>(
      (ref) => SavedSignalsNotifier(),
    );

// Saved Signals List Provider (direct access to saved signals)
final savedSignalsListProvider = Provider<List<Signal>>((ref) {
  return ref.watch(savedSignalsProvider);
});

// Helper function to create unique signal ID
String createSignalId(Signal signal) {
  return '${signal.symbol}_${signal.signal}_${signal.time}';
}
