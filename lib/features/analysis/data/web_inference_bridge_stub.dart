import 'dart:typed_data';

abstract class WebInferenceBridge {
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  });
}

WebInferenceBridge createWebInferenceBridge() {
  throw UnsupportedError('Web inference bridge is only available on web.');
}
