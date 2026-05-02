import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

// Settings Service Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// Base URL Provider (reactive)
final baseUrlProvider = StateNotifierProvider<BaseUrlNotifier, String>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return BaseUrlNotifier(service);
});

class BaseUrlNotifier extends StateNotifier<String> {
  final SettingsService _service;

  BaseUrlNotifier(this._service) : super(_service.getBaseUrl());

  Future<void> updateUrl(String url) async {
    await _service.setBaseUrl(url);
    state = url;
  }

  Future<void> resetToDefault() async {
    await _service.resetToDefault();
    state = _service.getBaseUrl();
  }

  void refresh() {
    state = _service.getBaseUrl();
  }
}

// Initialize Settings Provider
final initializeSettingsProvider = FutureProvider<void>((ref) async {
  final service = ref.read(settingsServiceProvider);
  await service.init();
  ref.read(baseUrlProvider.notifier).refresh();
});
