import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/core/models/analysis_record.dart';

final latestAnalysisProvider = StateProvider<AnalysisRecord?>((ref) => null);
