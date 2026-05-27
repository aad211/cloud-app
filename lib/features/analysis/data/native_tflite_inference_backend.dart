import 'package:flutter/foundation.dart';
import 'package:cloud_app/features/analysis/data/analysis_inference_backend.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class NativeTfliteInferenceBackend implements AnalysisInferenceBackend {
  NativeTfliteInferenceBackend({
    Future<Interpreter> Function()? loadInterpreter,
  }) : _loadInterpreter = loadInterpreter;

  static const modelAssetPath = 'assets/models/cloud.tflite';

  final Future<Interpreter> Function()? _loadInterpreter;

  Interpreter? _interpreter;
  Future<Interpreter>? _interpreterFuture;

  @override
  Future<List<double>> infer({
    required Float32List input,
    required int height,
    required int width,
    required int channels,
  }) async {
    final interpreter = await _ensureInterpreter();
    final inputTensor = input.toList(growable: false).reshape<double>([
      1,
      height,
      width,
      channels,
    ]);
    final outputTensor = interpreter.getOutputTensors().first;
    final outputShape = outputTensor.shape;
    final output = _createOutputBuffer(outputShape);

    interpreter.run(inputTensor, output);

    return _flattenNumbers(output);
  }

  Future<Interpreter> _ensureInterpreter() async {
    if (_interpreter != null) {
      return _interpreter!;
    }
    _interpreterFuture ??= _createInterpreter();
    _interpreter = await _interpreterFuture!;
    return _interpreter!;
  }

  Future<Interpreter> _createInterpreter() async {
    try {
      if (_loadInterpreter != null) {
        return _loadInterpreter();
      }
      return Interpreter.fromAsset(modelAssetPath);
    } on FlutterError catch (_) {
      throw StateError(
        'Native cough model asset is missing at $modelAssetPath. '
        'Add and register the real cloud.tflite file before running analysis.',
      );
    }
  }

  Object _createOutputBuffer(List<int> shape) {
    if (shape.isEmpty) {
      return 0.0;
    }
    final totalElements = shape.fold<int>(
      1,
      (product, value) => product * value,
    );
    final flat = List<double>.filled(totalElements, 0.0, growable: false);
    if (shape.length == 1) {
      return flat;
    }
    return flat.reshape<double>(shape);
  }

  List<double> _flattenNumbers(Object value) {
    if (value is num) {
      return [value.toDouble()];
    }
    if (value is List) {
      return value
          .expand<double>((item) => _flattenNumbers(item))
          .toList(growable: false);
    }
    throw StateError('Native inference output contained a non-numeric value.');
  }
}

AnalysisInferenceBackend createDefaultAnalysisInferenceBackend() {
  return NativeTfliteInferenceBackend();
}
