import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import 'package:ohok_flutter/features/analysis/presentation/analysis_history_controller.dart';

import '../../test_helpers/fake_local_storage_service.dart';

ProviderContainer _buildContainer(FakeLocalStorageService storage) {
  return ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
    ],
  );
}

void main() {
  test('AnalysisRecord round-trips through JSON', () {
    final record = AnalysisRecord(
      id: 'rec-1',
      date: DateTime(2025, 6, 15, 14, 30),
      condition: 'Asthma',
      percentage: 87,
    );

    final decoded = AnalysisRecord.fromJson(record.toJson());

    expect(decoded.id, record.id);
    expect(decoded.date, record.date);
    expect(decoded.condition, record.condition);
    expect(decoded.percentage, record.percentage);
  });

  test('addRecord prepends a record and persists the updated history', () async {
    final existing = AnalysisRecord(
      id: 'existing',
      date: DateTime(2025, 6, 15, 14, 30),
      condition: 'Asthma',
      percentage: 87,
    );
    final incoming = AnalysisRecord(
      id: 'incoming',
      date: DateTime(2025, 6, 16, 9),
      condition: 'Bronchitis',
      percentage: 65,
    );
    final storage = FakeLocalStorageService()
      ..history = [existing.toJson()];
    final container = _buildContainer(storage);
    addTearDown(container.dispose);

    await container.read(analysisHistoryProvider.future);
    await container.read(analysisHistoryProvider.notifier).addRecord(incoming);

    final state = container.read(analysisHistoryProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state, hasLength(2));
    expect(state!.first.id, incoming.id);
    expect(state.last.id, existing.id);
    expect(storage.history, hasLength(2));
    expect(storage.history.first['id'], incoming.id);
  });

  test('build filters malformed persisted records and keeps valid history',
      () async {
    final validRecord = AnalysisRecord(
      id: 'valid',
      date: DateTime(2025, 6, 15, 14, 30),
      condition: 'Asthma',
      percentage: 87,
    );
    final storage = FakeLocalStorageService()
      ..history = [
        validRecord.toJson(),
        {
          'id': 'broken',
          'date': 'not-a-date',
          'condition': 'Bronchitis',
          'percentage': 65,
        },
      ];
    final reportedErrors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    final container = _buildContainer(storage);

    FlutterError.onError = reportedErrors.add;
    addTearDown(() {
      FlutterError.onError = originalOnError;
      container.dispose();
    });

    final records = await container.read(analysisHistoryProvider.future);

    expect(records, hasLength(1));
    expect(records.single.id, validRecord.id);
    expect(storage.history, [validRecord.toJson()]);
    expect(reportedErrors, hasLength(1));
  });

  test('addRecord leaves state unchanged when persistence fails', () async {
    final existing = AnalysisRecord(
      id: 'existing',
      date: DateTime(2025, 6, 15, 14, 30),
      condition: 'Asthma',
      percentage: 87,
    );
    final incoming = AnalysisRecord(
      id: 'incoming',
      date: DateTime(2025, 6, 16, 9),
      condition: 'Bronchitis',
      percentage: 65,
    );
    final storage = FakeLocalStorageService()
      ..history = [existing.toJson()]
      ..historySaveException = Exception('save failed');
    final container = _buildContainer(storage);
    addTearDown(container.dispose);

    await container.read(analysisHistoryProvider.future);

    await expectLater(
      container.read(analysisHistoryProvider.notifier).addRecord(incoming),
      throwsException,
    );

    final state = container.read(analysisHistoryProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state, hasLength(1));
    expect(state!.single.id, existing.id);
    expect(storage.history, [existing.toJson()]);
  });
}
