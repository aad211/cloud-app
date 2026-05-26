import 'package:flutter/material.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/models/condition_probability.dart';

class ResultSummary {
  const ResultSummary({required this.record, required this.probabilities});

  final AnalysisRecord record;
  final List<ConditionProbability> probabilities;

  ConditionProbability get primaryProbability => probabilities.first;

  String get riskLabel =>
      primaryProbability.percentage >= 60 ? 'Medium Risk' : 'Low Risk';

  Color get riskColor =>
      primaryProbability.percentage >= 60 ? AppColors.gold : AppColors.success;
}

ResultSummary buildResultSummary([AnalysisRecord? record]) {
  final resolvedRecord = record ?? _fallbackRecord;
  final probabilities =
      resolvedRecord.probabilities.isNotEmpty
          ? resolvedRecord.probabilities
          : [
            ConditionProbability(
              name: resolvedRecord.condition,
              percentage: resolvedRecord.percentage,
              hexColor: _fallbackColorFor(resolvedRecord.condition),
            ),
          ];
  return ResultSummary(record: resolvedRecord, probabilities: probabilities);
}

final _fallbackRecord = AnalysisRecord(
  id: 'fallback-analysis',
  date: DateTime(2025, 1, 1),
  condition: 'Bronchitis',
  percentage: 65,
  probabilities: const [
    ConditionProbability(
      name: 'Bronchitis',
      percentage: 65,
      hexColor: 0xFFFAB95B,
    ),
    ConditionProbability(name: 'Healthy', percentage: 15, hexColor: 0xFF22C55E),
    ConditionProbability(name: 'Asthma', percentage: 8, hexColor: 0xFF547792),
    ConditionProbability(
      name: 'Pneumonia',
      percentage: 7,
      hexColor: 0xFFEF4444,
    ),
    ConditionProbability(name: 'COVID-19', percentage: 3, hexColor: 0xFFEF4444),
    ConditionProbability(
      name: 'Lung Cancer',
      percentage: 2,
      hexColor: 0xFF991B1B,
    ),
  ],
);

int _fallbackColorFor(String condition) {
  return switch (condition) {
    'Healthy' => AppColors.success.value,
    'Pneumonia' || 'COVID-19' || 'Lung Cancer' => AppColors.critical.value,
    _ => AppColors.gold.value,
  };
}
