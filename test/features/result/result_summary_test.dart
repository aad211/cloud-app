import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/models/condition_probability.dart';
import 'package:cloud_app/features/result/presentation/result_summary.dart';

void main() {
  test(
    'builds one source of truth for a real result summary and probabilities',
    () {
      final summary = buildResultSummary(_recordWithProbabilities());

      expect(summary.record.condition, summary.primaryProbability.name);
      expect(summary.record.percentage, summary.primaryProbability.percentage);
      expect(summary.probabilities, hasLength(2));
      expect(summary.probabilities[1].name, 'Healthy');
    },
  );

  test('uses Medium Risk with gold styling at 65 percent', () {
    final summary = buildResultSummary(
      AnalysisRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        condition: 'Bronchitis',
        percentage: 65,
        probabilities: const [
          ConditionProbability(
            name: 'Bronchitis',
            percentage: 65,
            hexColor: 0xFFFAB95B,
          ),
        ],
      ),
    );

    expect(summary.riskLabel, 'Medium Risk');
    expect(summary.riskColor, AppColors.gold);
  });

  test('throws when no analysis record is provided', () {
    expect(
      () => buildResultSummary(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No analysis record available.',
        ),
      ),
    );
  });

  test('falls back to Low Risk with green styling below 60 percent', () {
    final summary = buildResultSummary(
      AnalysisRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        condition: 'Healthy',
        percentage: 59,
        probabilities: const [
          ConditionProbability(
            name: 'Healthy',
            percentage: 59,
            hexColor: 0xFF22C55E,
          ),
        ],
      ),
    );

    expect(summary.riskLabel, 'Low Risk');
    expect(summary.riskColor, AppColors.success);
  });

  test('derives a probability from the real record when probabilities are empty', () {
    final summary = buildResultSummary(
      AnalysisRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        condition: 'Healthy',
        percentage: 29,
        probabilities: const [],
      ),
    );

    expect(summary.probabilities, hasLength(1));
    expect(summary.primaryProbability.name, 'Healthy');
    expect(summary.primaryProbability.percentage, 29);
    expect(summary.riskLabel, 'Low Risk');
    expect(summary.riskColor, AppColors.success);
  });
}

AnalysisRecord _recordWithProbabilities() {
  return AnalysisRecord(
    id: '1',
    date: DateTime(2024, 1, 1),
    condition: 'Bronchitis',
    percentage: 72,
    probabilities: const [
      ConditionProbability(
        name: 'Bronchitis',
        percentage: 72,
        hexColor: 0xFFFAB95B,
      ),
      ConditionProbability(
        name: 'Healthy',
        percentage: 28,
        hexColor: 0xFF22C55E,
      ),
    ],
  );
}
