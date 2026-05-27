import 'dart:typed_data';

import 'package:cloud_app/features/analysis/data/analysis_inference_backend.dart';

import 'web_inference_bridge_stub.dart'
    if (dart.library.js_interop) 'web_inference_bridge_web.dart';

class WebJsInferenceBackend implements AnalysisInferenceBackend {
  WebJsInferenceBackend({WebInferenceBridge? bridge})
    : _bridge = bridge ?? createWebInferenceBridge();

  final WebInferenceBridge _bridge;

  @override
  Future<List<int>> getExpectedInputShape() async {
    // For web, we need to load the model to inspect its shape
    // The web bridge doesn't expose shape introspection, so we return
    // the hardcoded shape that matches the model we're using
    // TODO: enhance web bridge to expose model.inputs[0].shape if needed
    return const [320, 320, 1];
  }

  @override
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  }) {
    return _bridge.infer(
      input: input,
      height: height,
      width: width,
      channels: channels,
    );
  }
}

AnalysisInferenceBackend createDefaultAnalysisInferenceBackend() {
  return WebJsInferenceBackend();
}
