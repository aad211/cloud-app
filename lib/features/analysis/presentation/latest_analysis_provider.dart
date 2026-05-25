import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';

final latestAnalysisProvider = StateProvider<AnalysisRecord?>((ref) => null);
