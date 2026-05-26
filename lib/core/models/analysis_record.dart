import 'package:cloud_flutter/core/models/condition_probability.dart';

class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.date,
    required this.condition,
    required this.percentage,
    this.probabilities = const [],
    this.audioFilePath,
    this.spectrogramFilePath,
    this.repoMirrorPath,
    this.storageBackend,
  });

  final String id;
  final DateTime date;
  final String condition;
  final int percentage;
  final List<ConditionProbability> probabilities;
  final String? audioFilePath;
  final String? spectrogramFilePath;
  final String? repoMirrorPath;
  final String? storageBackend;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'condition': condition,
    'percentage': percentage,
    'probabilities': probabilities.map((item) => item.toJson()).toList(),
    'audioFilePath': audioFilePath,
    'spectrogramFilePath': spectrogramFilePath,
    'repoMirrorPath': repoMirrorPath,
    'storageBackend': storageBackend,
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
    final rawProbabilities = json['probabilities'];
    final parsedProbabilities =
        rawProbabilities is List
            ? rawProbabilities.indexed.map((entry) {
                final index = entry.$1;
                final rawProbability = entry.$2;

                if (rawProbability is! Map) {
                  throw FormatException(
                    'Analysis record has an invalid probability entry at index $index.',
                  );
                }

                try {
                  return ConditionProbability.fromJson(
                    Map<String, dynamic>.from(rawProbability),
                  );
                } on FormatException catch (_) {
                  throw FormatException(
                    'Analysis record has an invalid probability entry at index $index.',
                  );
                } on TypeError {
                  throw FormatException(
                    'Analysis record has an invalid probability entry at index $index.',
                  );
                }
              }).toList(growable: false)
            : const <ConditionProbability>[];

    final audioFilePath = json['audioFilePath'];
    if (audioFilePath != null && audioFilePath is! String) {
      throw const FormatException(
        'Analysis record has an invalid audioFilePath.',
      );
    }
    final spectrogramFilePath = json['spectrogramFilePath'];
    if (spectrogramFilePath != null && spectrogramFilePath is! String) {
      throw const FormatException(
        'Analysis record has an invalid spectrogramFilePath.',
      );
    }
    final repoMirrorPath = json['repoMirrorPath'];
    if (repoMirrorPath != null && repoMirrorPath is! String) {
      throw const FormatException(
        'Analysis record has an invalid repoMirrorPath.',
      );
    }
    final storageBackend = json['storageBackend'];
    if (storageBackend != null && storageBackend is! String) {
      throw const FormatException(
        'Analysis record has an invalid storageBackend.',
      );
    }

    return AnalysisRecord(
      id: id,
      date: date,
      condition: condition,
      percentage: parsedPercentage,
      probabilities: parsedProbabilities,
      audioFilePath: audioFilePath as String?,
      spectrogramFilePath: spectrogramFilePath as String?,
      repoMirrorPath: repoMirrorPath as String?,
      storageBackend: storageBackend as String?,
    );
  }
}
