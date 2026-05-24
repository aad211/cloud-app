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

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) => AnalysisRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        condition: json['condition'] as String,
        percentage: json['percentage'] as int,
      );
}
