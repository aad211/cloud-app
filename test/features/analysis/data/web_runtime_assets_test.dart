import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web inference keeps its model at the dedicated web-local path', () {
    final source = File('web/cough_inference.js').readAsStringSync();

    expect(source, contains("const MODEL_URL = 'models/cloud.tflite';"));
  });

  test('web bootstrap loads TensorFlow.js and tfjs-tflite before cough inference', () {
    final html = File('web/index.html').readAsStringSync();

    expect(
      html,
      contains(
        'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs/dist/tf.min.js',
      ),
    );
    expect(
      html,
      contains(
        'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite/dist/tf-tflite.min.js',
      ),
    );
    expect(html.indexOf('tf.min.js'), lessThan(html.indexOf('cough_inference.js')));
    expect(
      html.indexOf('tf-tflite.min.js'),
      lessThan(html.indexOf('cough_inference.js')),
    );
  });

  test('web cough inference uses the TensorFlow.js TFLite prediction flow', () {
    final source = File('web/cough_inference.js').readAsStringSync();

    expect(source, contains('tflite.loadTFLiteModel'));
    expect(source, contains('tf.tensor'));
    expect(source, contains('.predict('));
    expect(source, contains('.data()'));
  });
}
