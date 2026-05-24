import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageService {
  Future<bool> getHasCompletedOnboarding();
  /// Persists [value] and returns `true` on success, `false` on failure.
  Future<bool> setHasCompletedOnboarding(bool value);
  Future<List<Map<String, dynamic>>> loadAnalysisHistory();
  /// Persists analysis history or throws if the write cannot be completed.
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
      final records = <Map<String, dynamic>>[];
      var droppedInvalidEntries = false;

      for (final entry in decoded) {
        try {
          if (entry is Map<String, dynamic>) {
            records.add(entry);
            continue;
          }
          if (entry is Map) {
            records.add(Map<String, dynamic>.from(entry));
            continue;
          }
          throw FormatException('Expected map entry, got ${entry.runtimeType}');
        } on FormatException catch (e, st) {
          droppedInvalidEntries = true;
          _reportHistoryError(
            exception: e,
            stackTrace: st,
            context:
                'Invalid analysisHistory entry in SharedPreferences; dropping entry.',
          );
        } on TypeError catch (e, st) {
          droppedInvalidEntries = true;
          _reportHistoryError(
            exception: e,
            stackTrace: st,
            context:
                'Type error reading analysisHistory entry from SharedPreferences; dropping entry.',
          );
        }
      }

      if (droppedInvalidEntries) {
        await _persistCleanedHistory(records);
      }

      return records;
    } on FormatException catch (e, st) {
      _reportHistoryError(
        exception: e,
        stackTrace: st,
        context:
            'Corrupted analysisHistory in SharedPreferences; resetting to empty.',
      );
      await _prefs.remove(_historyKey);
      return [];
    } on TypeError catch (e, st) {
      _reportHistoryError(
        exception: e,
        stackTrace: st,
        context:
            'Type error reading analysisHistory from SharedPreferences; resetting to empty.',
      );
      await _prefs.remove(_historyKey);
      return [];
    }
  }

  @override
  Future<void> saveAnalysisHistory(List<Map<String, dynamic>> records) async {
    final didSave = await _prefs.setString(_historyKey, jsonEncode(records));
    if (!didSave) {
      throw StateError('Failed to persist analysis history.');
    }
  }

  Future<void> _persistCleanedHistory(List<Map<String, dynamic>> records) async {
    final didSave = await _prefs.setString(_historyKey, jsonEncode(records));
    if (!didSave) {
      _reportHistoryError(
        exception: StateError('Failed to persist cleaned analysis history.'),
        stackTrace: StackTrace.current,
        context:
            'Dropped invalid analysisHistory entries but could not persist the cleaned result.',
      );
    }
  }

  void _reportHistoryError({
    required Object exception,
    required StackTrace stackTrace,
    required String context,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
        library: 'local_storage_service',
        context: ErrorDescription(context),
      ),
    );
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Override localStorageServiceProvider in bootstrap');
});
