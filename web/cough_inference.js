(function () {
  // The web backend needs a directly fetchable model URL for tfjs-tflite, so it
  // intentionally loads the separate web-local copy instead of a Flutter asset key.
  const MODEL_URL = 'models/cloud.tflite';
  let modelPromise;

  async function loadModel() {
    const tf = globalThis.tf || null;
    const tflite = globalThis.tflite || null;

    if (!tf || typeof tf.tensor !== 'function') {
      throw new Error(
        'TensorFlow.js is not available. Load tf.min.js before using web analysis.',
      );
    }

    if (!tflite || typeof tflite.loadTFLiteModel !== 'function') {
      throw new Error(
        'TensorFlow.js TFLite is not available. Load tf-tflite.min.js before using web analysis.',
      );
    }

    const modelResponse = await fetch(MODEL_URL);
    if (!modelResponse.ok) {
      throw new Error(
        `Missing cough model at ${MODEL_URL}. Add the real cloud.tflite file before running web analysis.`,
      );
    }

    return tflite.loadTFLiteModel(MODEL_URL);
  }

  async function infer(input, height, width, channels) {
    const tf = globalThis.tf || null;

    if (!ArrayBuffer.isView(input)) {
      throw new Error('Web inference expected a typed-array input tensor.');
    }

    if (!tf || typeof tf.tensor !== 'function') {
      throw new Error(
        'TensorFlow.js is not available. Load tf.min.js before using web analysis.',
      );
    }

    modelPromise ??= loadModel();
    const model = await modelPromise;

    if (!model || typeof model.predict !== 'function') {
      throw new Error(
        'The browser TensorFlow Lite runtime did not provide a predict() function.',
      );
    }

    const inputTensor = tf.tensor(input, [1, height, width, channels], 'float32');
    let outputTensor;

    try {
      const output = model.predict(inputTensor);
      outputTensor = Array.isArray(output) ? output[0] : output;

      if (!outputTensor || typeof outputTensor.data !== 'function') {
        throw new Error(
          'Web inference runtime returned a non-tensor score payload.',
        );
      }

      const result = await outputTensor.data();
      return Array.from(result, (value) => Number(value));
    } finally {
      inputTensor.dispose();
      if (outputTensor && typeof outputTensor.dispose === 'function') {
        outputTensor.dispose();
      }
    }
  }

  globalThis.ohokCoughInference = {
    infer,
  };
})();
