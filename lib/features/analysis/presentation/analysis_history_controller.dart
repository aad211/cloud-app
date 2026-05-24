import 'package:flutter/foundation.dart';
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
    final records = <AnalysisRecord>[];
    var hasInvalidEntries = false;

    for (final raw in rawList) {
      try {
        records.add(AnalysisRecord.fromJson(raw));
      } on FormatException catch (error, stackTrace) {
        hasInvalidEntries = true;
        _reportInvalidRecord(error, stackTrace);
      } on TypeError catch (error, stackTrace) {
        hasInvalidEntries = true;
        _reportInvalidRecord(error, stackTrace);
      }
    }

    if (hasInvalidEntries) {
      await storage.saveAnalysisHistory(
        records.map((record) => record.toJson()).toList(),
      );
    }

    return records;
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

  void _reportInvalidRecord(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'analysis_history_controller',
        context: ErrorDescription(
          'Invalid analysis record in persisted history; dropping entry.',
        ),
      ),
    );
  }
}
