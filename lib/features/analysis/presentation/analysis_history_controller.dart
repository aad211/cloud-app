import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';

final analysisHistoryProvider =
    AsyncNotifierProvider<AnalysisHistoryController, List<AnalysisRecord>>(
  AnalysisHistoryController.new,
);

class AnalysisHistoryController
    extends AsyncNotifier<List<AnalysisRecord>> {
  @override
  Future<List<AnalysisRecord>> build() async {
    final storage = ref.read(localStorageServiceProvider);
    final rawList = await storage.loadAnalysisHistory();
    return rawList.map(AnalysisRecord.fromJson).toList();
  }

  Future<void> addRecord(AnalysisRecord record) async {
    final storage = ref.read(localStorageServiceProvider);
    final current = state.valueOrNull ?? [];
    final updated = [record, ...current];
    state = AsyncData(updated);
    await storage.saveAnalysisHistory(
      updated.map((r) => r.toJson()).toList(),
    );
  }
}
