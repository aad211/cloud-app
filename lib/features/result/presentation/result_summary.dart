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
  if (record == null) {
    throw StateError('No analysis record available.');
  }

  final probabilities =
      record.probabilities.isNotEmpty
          ? record.probabilities
          : [
            ConditionProbability(
              name: record.condition,
              percentage: record.percentage,
              hexColor: _fallbackColorFor(record.condition),
            ),
          ];
  return ResultSummary(record: record, probabilities: probabilities);
}

int _fallbackColorFor(String condition) {
  return switch (condition) {
    'Healthy' => AppColors.success.value,
    'Pneumonia' || 'COVID-19' || 'Lung Cancer' => AppColors.critical.value,
    _ => AppColors.gold.value,
  };
}
