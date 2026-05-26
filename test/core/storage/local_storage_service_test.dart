import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_flutter/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadAnalysisHistory keeps valid entries when one list item is invalid',
      () async {
    final validRecord = {
      'id': 'valid',
      'date': '2025-06-15T14:30:00.000',
      'condition': 'Asthma',
      'percentage': 87,
    };
    final reportedErrors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;

    SharedPreferences.setMockInitialValues({
      'analysisHistory': jsonEncode([validRecord, 'invalid-entry']),
    });
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = originalOnError);

    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPrefsLocalStorageService(prefs);

    final history = await storage.loadAnalysisHistory();

    expect(history, [validRecord]);
    expect(jsonDecode(prefs.getString('analysisHistory')!), [validRecord]);
    expect(reportedErrors, hasLength(1));
  });
}
