import 'dart:typed_data';

abstract class AnalysisInferenceBackend {
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  });

  /// Returns the expected input shape from the model: [height, width, channels]
  Future<List<int>> getExpectedInputShape();
}
