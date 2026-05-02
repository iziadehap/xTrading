import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/signal_model.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String get signalsAll => '$baseUrl/signals/all';
  String get signalsBuy => '$baseUrl/signals/buy';
  String get signalsWait => '$baseUrl/signals/wait';
  String get signalsFailed => '$baseUrl/signals/failed';
  String get signalsLatest => '$baseUrl/signals/latest';

  Future<List<Signal>> fetchAllSignals() async {
    return _fetchSignals(signalsAll);
  }

  Future<List<Signal>> fetchBuySignals() async {
    return _fetchSignals(signalsBuy);
  }

  Future<List<Signal>> fetchWaitSignals() async {
    return _fetchSignals(signalsWait);
  }

  Future<List<Signal>> fetchFailedSignals() async {
    return _fetchSignals(signalsFailed);
  }

  Future<List<Signal>> fetchLatestSignals() async {
    return _fetchSignals(signalsLatest);
  }

  Future<List<Signal>> _fetchSignals(String url) async {
    try {
      debugPrint('Fetching: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Signal.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        debugPrint('API endpoint not found: ${response.statusCode}');
        throw Exception('API endpoint not found. Please check the server URL.');
      } else if (response.statusCode >= 500) {
        debugPrint('Server error: ${response.statusCode}');
        throw Exception(
          'Server is temporarily unavailable. Please try again later.',
        );
      } else {
        debugPrint('Failed to load signals: ${response.statusCode}');
        throw Exception('Failed to load signals (HTTP ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching signals: $e');
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('Host lookup failed')) {
        throw Exception(
          'Unable to connect to server. Please check your internet connection and server URL.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timed out. Please check your connection and try again.',
        );
      } else {
        throw Exception('Error fetching signals: $e');
      }
    }
  }
}
