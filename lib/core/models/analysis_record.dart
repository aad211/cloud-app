class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.date,
    required this.condition,
    required this.percentage,
  });

  final String id;
  final DateTime date;
  final String condition;
  final int percentage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'condition': condition,
        'percentage': percentage,
      };

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final dateRaw = json['date'];
    final condition = json['condition'];
    final percentage = json['percentage'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Analysis record is missing a valid id.');
    }
    if (dateRaw is! String) {
      throw const FormatException('Analysis record is missing a valid date.');
    }
    final date = DateTime.tryParse(dateRaw);
    if (date == null) {
      throw const FormatException('Analysis record has an invalid date.');
    }
    if (condition is! String || condition.isEmpty) {
      throw const FormatException(
        'Analysis record is missing a valid condition.',
      );
    }
    final parsedPercentage = switch (percentage) {
      int value => value,
      double value when value.isFinite && value.truncateToDouble() == value =>
        value.toInt(),
      _ => null,
    };
    if (parsedPercentage == null) {
      throw const FormatException(
        'Analysis record is missing a valid percentage.',
      );
    }

    return AnalysisRecord(
      id: id,
      date: date,
      condition: condition,
      percentage: parsedPercentage,
    );
  }
}
