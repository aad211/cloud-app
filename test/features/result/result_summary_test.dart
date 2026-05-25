import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/models/condition_probability.dart';
import 'package:ohok_flutter/features/result/presentation/result_summary.dart';

void main() {
  test(
    'builds one source of truth for the result summary and probabilities',
    () {
      final summary = buildResultSummary();

      expect(summary.record.condition, summary.primaryProbability.name);
      expect(summary.record.percentage, summary.primaryProbability.percentage);
      expect(summary.probabilities, hasLength(6));
    },
  );

  test('uses Medium Risk with gold styling at 65 percent', () {
    final summary = buildResultSummary();

    expect(summary.riskLabel, 'Medium Risk');
    expect(summary.riskColor, AppColors.gold);
  });

  test('falls back to Low Risk with green styling below 60 percent', () {
    final summary = ResultSummary(
      record: AnalysisRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        condition: 'Healthy',
        percentage: 59,
      ),
      probabilities: [
        const ConditionProbability(
          name: 'Healthy',
          percentage: 59,
          hexColor: 0xFF22C55E,
        ),
      ],
    );

    expect(summary.riskLabel, 'Low Risk');
    expect(summary.riskColor, AppColors.success);
  });

  test('does not surface High Risk for low-confidence mocked values', () {
    final summary = ResultSummary(
      record: AnalysisRecord(
        id: '1',
        date: DateTime(2024, 1, 1),
        condition: 'Healthy',
        percentage: 29,
      ),
      probabilities: [
        const ConditionProbability(
          name: 'Healthy',
          percentage: 29,
          hexColor: 0xFF22C55E,
        ),
      ],
    );

    expect(summary.riskLabel, 'Low Risk');
    expect(summary.riskColor, AppColors.success);
  });
}
