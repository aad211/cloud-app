class ConditionProbability {
  const ConditionProbability({
    required this.name,
    required this.percentage,
    required this.hexColor,
  });

  final String name;
  final int percentage;
  final int hexColor;

  Map<String, dynamic> toJson() => {
    'name': name,
    'percentage': percentage,
    'hexColor': hexColor,
  };

  factory ConditionProbability.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final percentage = json['percentage'];
    final hexColor = json['hexColor'];

    if (name is! String || name.isEmpty) {
      throw const FormatException(
        'Condition probability is missing a valid name.',
      );
    }
    if (percentage is! int) {
      throw const FormatException(
        'Condition probability is missing a valid percentage.',
      );
    }
    if (hexColor is! int) {
      throw const FormatException(
        'Condition probability is missing a valid hexColor.',
      );
    }

    return ConditionProbability(
      name: name,
      percentage: percentage,
      hexColor: hexColor,
    );
  }
}
