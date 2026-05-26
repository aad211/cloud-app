@JS('globalThis.cloudCoughInference')
library;

import 'dart:js_interop';
import 'dart:typed_data';

abstract class WebInferenceBridge {
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  });
}

@JS()
@staticInterop
class _OhokCoughInference {}

extension on _OhokCoughInference {
  external JSPromise<JSArray<JSNumber>> infer(
    JSFloat32Array input,
    JSNumber height,
    JSNumber width,
    JSNumber channels,
  );
}

@JS('globalThis.cloudCoughInference')
external _OhokCoughInference? get _inferenceBridge;

class WindowWebInferenceBridge implements WebInferenceBridge {
  @override
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  }) async {
    final inferenceBridge = _inferenceBridge;
    if (inferenceBridge == null) {
      throw StateError(
        'window.cloudCoughInference is not available. '
        'Ensure web/cough_inference.js is loaded before starting analysis.',
      );
    }

    final result =
        await inferenceBridge
            .infer(input.toJS, height.toJS, width.toJS, channels.toJS)
            .toDart;

    return result.toDart
        .map((value) => value.toDartDouble)
        .toList(growable: false);
  }
}

WebInferenceBridge createWebInferenceBridge() => WindowWebInferenceBridge();
