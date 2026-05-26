import 'dart:typed_data';

import 'package:ohok_flutter/features/analysis/data/analysis_inference_backend.dart';

import 'web_inference_bridge_stub.dart'
    if (dart.library.js_interop) 'web_inference_bridge_web.dart';

class WebJsInferenceBackend implements AnalysisInferenceBackend {
  WebJsInferenceBackend({WebInferenceBridge? bridge})
    : _bridge = bridge ?? createWebInferenceBridge();

  final WebInferenceBridge _bridge;

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
