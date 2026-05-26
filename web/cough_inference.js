(function () {
  const MODEL_URL = 'models/cloud.tflite';
  let runnerPromise;

  async function loadRunner() {
    const modelResponse = await fetch(MODEL_URL);
    if (!modelResponse.ok) {
      throw new Error(
        `Missing cough model at ${MODEL_URL}. Add the real cloud.tflite file before running web analysis.`,
      );
    }

    const runtime =
      globalThis.ohokTfliteRuntime ||
      globalThis.tflite ||
      globalThis.tfLite ||
      null;

    if (!runtime || typeof runtime.loadModel !== 'function') {
      throw new Error(
        'No browser TensorFlow Lite runtime is available. Load the runtime before using web analysis.',
      );
    }

    const modelBytes = await modelResponse.arrayBuffer();
    return runtime.loadModel(modelBytes);
  }

  async function infer(input, height, width, channels) {
    if (!ArrayBuffer.isView(input)) {
      throw new Error('Web inference expected a typed-array input tensor.');
    }

    runnerPromise ??= loadRunner();
    const runner = await runnerPromise;

    if (!runner || typeof runner.infer !== 'function') {
      throw new Error(
        'The browser TensorFlow Lite runtime did not provide an infer() function.',
      );
    }

    const result = await runner.infer({
      input,
      height,
      width,
      channels,
    });

    if (!Array.isArray(result)) {
      throw new Error('Web inference runtime returned a non-array score payload.');
    }

    return result.map((value) => Number(value));
  }

  globalThis.ohokCoughInference = {
    infer,
  };
})();
