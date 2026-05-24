import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageService {
  Future<bool> getHasCompletedOnboarding();
  /// Persists [value] and returns `true` on success, `false` on failure.
  Future<bool> setHasCompletedOnboarding(bool value);
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
  Future<bool> setHasCompletedOnboarding(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  @override
  Future<List<Map<String, dynamic>>> loadAnalysisHistory() async {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw FormatException('Expected a JSON array, got ${decoded.runtimeType}');
      }
      return decoded
          .map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            throw FormatException('Expected map entry, got ${e.runtimeType}');
          })
          .toList();
    } on FormatException catch (e, st) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: st,
        library: 'local_storage_service',
        context: ErrorDescription(
          'Corrupted analysisHistory in SharedPreferences; resetting to empty.',
        ),
      ));
      await _prefs.remove(_historyKey);
      return [];
    } on TypeError catch (e, st) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: st,
        library: 'local_storage_service',
        context: ErrorDescription(
          'Type error reading analysisHistory from SharedPreferences; resetting to empty.',
        ),
      ));
      await _prefs.remove(_historyKey);
      return [];
    }
  }

  @override
  Future<void> saveAnalysisHistory(List<Map<String, dynamic>> records) async {
    await _prefs.setString(_historyKey, jsonEncode(records));
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Override localStorageServiceProvider in bootstrap');
});
