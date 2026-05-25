import 'package:flutter/material.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/models/condition_probability.dart';
import 'package:ohok_flutter/features/analysis/data/mock_analysis_repository.dart';

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

ResultSummary buildResultSummary([
  MockAnalysisRepository repository = const MockAnalysisRepository(),
]) {
  return ResultSummary(
    record: repository.buildRecord(),
    probabilities: repository.probabilities(),
  );
}
