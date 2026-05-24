import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/core/models/condition_probability.dart';

class MockAnalysisRepository {
  const MockAnalysisRepository();

  AnalysisRecord buildRecord() {
    return AnalysisRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      condition: 'Bronchitis',
      percentage: 65,
    );
  }

  List<ConditionProbability> probabilities() => const [
        ConditionProbability(
            name: 'Bronchitis', percentage: 65, hexColor: 0xFFFAB95B),
        ConditionProbability(
            name: 'Healthy', percentage: 15, hexColor: 0xFF22C55E),
        ConditionProbability(
            name: 'Asthma', percentage: 8, hexColor: 0xFF547792),
        ConditionProbability(
            name: 'Pneumonia', percentage: 7, hexColor: 0xFFEF4444),
        ConditionProbability(
            name: 'COVID-19', percentage: 3, hexColor: 0xFFEF4444),
        ConditionProbability(
            name: 'Lung Cancer', percentage: 2, hexColor: 0xFF991B1B),
      ];
}
