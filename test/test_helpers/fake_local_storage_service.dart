import 'package:ohok_flutter/core/storage/local_storage_service.dart';

class FakeLocalStorageService implements LocalStorageService {
  bool hasCompletedOnboarding = false;
  List<Map<String, dynamic>> history = [];

  /// Set to `true` to make [setHasCompletedOnboarding] simulate a write failure.
  bool shouldFailPersistence = false;

  @override
  Future<bool> getHasCompletedOnboarding() async => hasCompletedOnboarding;

  @override
  Future<bool> setHasCompletedOnboarding(bool value) async {
    if (shouldFailPersistence) return false;
    hasCompletedOnboarding = value;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> loadAnalysisHistory() async => history;

  @override
  Future<void> saveAnalysisHistory(List<Map<String, dynamic>> records) async {
    history = records;
  }
}
