import 'package:ohok_flutter/core/storage/local_storage_service.dart';

class FakeLocalStorageService implements LocalStorageService {
  bool hasCompletedOnboarding = false;
  List<Map<String, dynamic>> history = [];

  @override
  Future<bool> getHasCompletedOnboarding() async => hasCompletedOnboarding;

  @override
  Future<List<Map<String, dynamic>>> loadAnalysisHistory() async => history;

  @override
  Future<void> saveAnalysisHistory(List<Map<String, dynamic>> records) async {
    history = records;
  }

  @override
  Future<void> setHasCompletedOnboarding(bool value) async {
    hasCompletedOnboarding = value;
  }
}
