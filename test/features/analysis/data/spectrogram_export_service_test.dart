import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/features/analysis/data/spectrogram_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'native export saves the spectrogram and tolerates repo-mirror failure',
    () async {
      final writes = <String, Uint8List>{};
      final reportedErrors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = reportedErrors.add;
      addTearDown(() => FlutterError.onError = originalOnError);

      final service = SpectrogramExportService(
        isWeb: false,
        getDocumentsDirectoryPath: () async => '/virtual/documents',
        resolveRepoRootDirectoryPath: () async => '/virtual/repo',
        writeBytesToFile: (path, bytes) async {
          if (path.contains('analysis_outputs')) {
            throw StateError('mirror write failed');
          }
          writes[path] = Uint8List.fromList(bytes);
        },
      );

      final result = await service.export(
        analysisId: 'native-case',
        melSpectrogram: const [
          [0.0, 2.0],
          [1.0, 3.0],
        ],
      );

      expect(result.storageBackend, 'native');
      expect(result.repoMirrorPath, isNull);
      expect(result.spectrogramFilePath, contains('spectrograms'));

      final savedBytes = writes[result.spectrogramFilePath];
      expect(savedBytes, isNotNull);
      expect(savedBytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);

      expect(reportedErrors, hasLength(1));
      expect(reportedErrors.single.library, 'spectrogram_export_service');
      expect(
        reportedErrors.single.context.toString(),
        contains('Failed to persist spectrogram repo mirror.'),
      );
    },
    skip: kIsWeb,
  );

  test('web export stores a browser key instead of a file path', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = SpectrogramExportService(
      isWeb: true,
      getSharedPreferences: () async => prefs,
      getDocumentsDirectoryPath: () async {
        fail('web export should not request a documents directory');
      },
      resolveRepoRootDirectoryPath: () async {
        fail('web export should not attempt a repo mirror');
      },
    );

    final result = await service.export(
      analysisId: 'web-case',
      melSpectrogram: const [
        [0.0, 0.5, 1.0],
        [1.0, 0.5, 0.0],
      ],
    );

    expect(result.storageBackend, 'browser');
    expect(result.repoMirrorPath, isNull);
    expect(result.spectrogramFilePath, 'spectrogram/web-case');

    final storedValue = prefs.getString(result.spectrogramFilePath);
    expect(storedValue, isNotNull);
    expect(base64Decode(storedValue!).take(8), [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
    ]);
  });

  test(
    'web export throws when browser storage cannot persist the PNG',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final service = SpectrogramExportService(
        isWeb: true,
        getSharedPreferences: () async => prefs,
        saveBrowserValue: (_, __) async => false,
      );

      await expectLater(
        () => service.export(
          analysisId: 'web-failure',
          melSpectrogram: const [
            [0.0, 1.0],
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to persist spectrogram in browser storage.',
          ),
        ),
      );
    },
  );

  test(
    'export sanitizes analysis ids before using storage locations',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final service = SpectrogramExportService(
        isWeb: true,
        getSharedPreferences: () async => prefs,
      );

      final result = await service.export(
        analysisId: '../unsafe id',
        melSpectrogram: const [
          [0.0, 1.0],
        ],
      );

      expect(result.spectrogramFilePath, 'spectrogram/..%2Funsafe%20id');
      expect(prefs.getString('spectrogram/..%2Funsafe%20id'), isNotNull);
    },
  );
}
