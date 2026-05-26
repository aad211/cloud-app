import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_flutter/core/models/analysis_record.dart';
import 'package:cloud_flutter/core/models/condition_probability.dart';

void main() {
  test('AnalysisRecord keeps old JSON readable and round-trips new fields', () {
    final legacy = AnalysisRecord.fromJson({
      'id': 'legacy-1',
      'date': '2026-05-25T12:00:00.000',
      'condition': 'Bronchitis',
      'percentage': 65,
    });

    expect(legacy.probabilities, isEmpty);
    expect(legacy.audioFilePath, isNull);
    expect(legacy.spectrogramFilePath, isNull);
    expect(legacy.storageBackend, isNull);

    final current = AnalysisRecord(
      id: 'real-1',
      date: DateTime.parse('2026-05-25T12:30:00.000'),
      condition: 'Asthma',
      percentage: 78,
      probabilities: const [
        ConditionProbability(
          name: 'Asthma',
          percentage: 78,
          hexColor: 0xFF547792,
        ),
        ConditionProbability(
          name: 'Healthy',
          percentage: 22,
          hexColor: 0xFF22C55E,
        ),
      ],
      audioFilePath: 'recordings/real-1.wav',
      spectrogramFilePath: 'spectrograms/real-1.png',
      repoMirrorPath: 'analysis_outputs/real-1.png',
      storageBackend: 'native',
    );

    final decoded = AnalysisRecord.fromJson(current.toJson());

    expect(decoded.condition, 'Asthma');
    expect(decoded.probabilities, hasLength(2));
    expect(decoded.probabilities.first.name, 'Asthma');
    expect(decoded.audioFilePath, 'recordings/real-1.wav');
    expect(decoded.spectrogramFilePath, 'spectrograms/real-1.png');
    expect(decoded.repoMirrorPath, 'analysis_outputs/real-1.png');
    expect(decoded.storageBackend, 'native');
  });

  test('AnalysisRecord rejects malformed probability entries', () {
    for (final invalidEntry in ['bad', 42, null]) {
      expect(
        () => AnalysisRecord.fromJson({
          'id': 'broken-1',
          'date': '2026-05-25T12:00:00.000',
          'condition': 'Bronchitis',
          'percentage': 65,
          'probabilities': [invalidEntry],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Analysis record has an invalid probability entry at index 0.',
          ),
        ),
      );
    }
  });

  test('AnalysisRecord wraps malformed probability maps with entry index', () {
    expect(
      () => AnalysisRecord.fromJson({
        'id': 'broken-2',
        'date': '2026-05-25T12:00:00.000',
        'condition': 'Bronchitis',
        'percentage': 65,
        'probabilities': [
          {
            'percentage': 65,
            'hexColor': 0xFF547792,
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Analysis record has an invalid probability entry at index 0.',
        ),
      ),
    );
  });
}
