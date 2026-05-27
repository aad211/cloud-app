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
    
    // Read the actual expected input shape from the model
    final inputTensor = interpreter.getInputTensor(0);
    final expectedShape = inputTensor.shape;
    
    if (expectedShape.length != 4) {
      throw StateError(
        'Unsupported model input shape: $expectedShape. Expected 4D tensor [batch, height, width, channels].',
      );
    }
    
    final expectedChannels = expectedShape[3];
    
    // The input was prepared assuming `channels`, but the model expects `expectedChannels`
    // We need to reshape/replicate the input to match
    final reshapedInput = _reshapeInput(
      input: input,
      sourceHeight: height,
      sourceWidth: width,
      sourceChannels: channels,
      targetChannels: expectedChannels,
    );
    
    final inputList = reshapedInput.toList(growable: false).reshape<double>([
      1,
      height,
      width,
      expectedChannels,
    ]);
    
    final outputTensor = interpreter.getOutputTensors().first;
    final outputShape = outputTensor.shape;
    final output = _createOutputBuffer(outputShape);

    interpreter.run(inputList, output);

    return _flattenNumbers(output);
  }
  
  Float32List _reshapeInput({
    required Float32List input,
    required int sourceHeight,
    required int sourceWidth,
    required int sourceChannels,
    required int targetChannels,
  }) {
    if (sourceChannels == targetChannels) {
      return input;
    }
    
    final targetSize = sourceHeight * sourceWidth * targetChannels;
    final reshaped = Float32List(targetSize);
    
    for (int y = 0; y < sourceHeight; y++) {
      for (int x = 0; x < sourceWidth; x++) {
        final srcIndex = (y * sourceWidth + x) * sourceChannels;
        final dstIndex = (y * sourceWidth + x) * targetChannels;
        
        if (sourceChannels == 1 && targetChannels == 3) {
          // Grayscale to RGB: replicate the single channel to all 3
          final value = input[srcIndex];
          reshaped[dstIndex + 0] = value;
          reshaped[dstIndex + 1] = value;
          reshaped[dstIndex + 2] = value;
        } else if (sourceChannels == 3 && targetChannels == 1) {
          // RGB to grayscale: average the channels
          final r = input[srcIndex + 0];
          final g = input[srcIndex + 1];
          final b = input[srcIndex + 2];
          reshaped[dstIndex] = (r + g + b) / 3.0;
        } else {
          // For other cases, just copy or pad with zeros
          for (int c = 0; c < targetChannels; c++) {
            reshaped[dstIndex + c] = c < sourceChannels ? input[srcIndex + c] : 0.0;
          }
        }
      }
    }
    
    return reshaped;
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
