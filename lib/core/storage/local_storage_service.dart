import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageService {
  Future<bool> getHasCompletedOnboarding();
  Future<void> setHasCompletedOnboarding(bool value);
  Future<List<Map<String, dynamic>>> loadAnalysisHistory();
  Future<void> saveAnalysisHistory(List<Map<String, dynamic>> records);
}

class SharedPrefsLocalStorageService implements LocalStorageService {
  SharedPrefsLocalStorageService(this._prefs);

  final SharedPreferences _prefs;
  static const _onboardingKey = 'hasCompletedOnboarding';
  static const _historyKey = 'analysisHistory';

  @override
  Future<bool> getHasCompletedOnboarding() async =>
      _prefs.getBool(_onboardingKey) ?? false;

  @override
  Future<void> setHasCompletedOnboarding(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  @override
  Future<List<Map<String, dynamic>>> loadAnalysisHistory() async {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> saveAnalysisHistory(List<Map<String, dynamic>> records) async {
    await _prefs.setString(_historyKey, jsonEncode(records));
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Override localStorageServiceProvider in bootstrap');
});
