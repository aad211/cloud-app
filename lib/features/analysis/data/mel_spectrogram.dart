import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

class MelSpectrogram {
  static List<List<double>> compute({
    required List<double> samples,
    required int sampleRate,
    required int fftSize,
    required int hopLength,
    required int melBins,
    required double minFreq,
    required double maxFreq,
  }) {
    if (fftSize <= 0 || hopLength <= 0 || melBins <= 0) {
      return const [];
    }

    final window = List<double>.generate(
      fftSize,
      (index) => 0.5 - 0.5 * cos((2 * pi * index) / (fftSize - 1)),
    );
    final fft = FFT(fftSize);
    final filterBank = _createMelFilterBank(
      sampleRate: sampleRate,
      fftSize: fftSize,
      melBins: melBins,
      minFreq: minFreq,
      maxFreq: maxFreq,
    );
    final frameCount =
        samples.length <= fftSize
            ? 1
            : 1 + ((samples.length - fftSize) ~/ hopLength);
    final mel = List.generate(
      melBins,
      (_) => List<double>.filled(frameCount, 0),
    );

    for (var frame = 0; frame < frameCount; frame += 1) {
      final start = frame * hopLength;
      final input = Float64List(fftSize);
      for (var i = 0; i < fftSize; i += 1) {
        final sampleIndex = start + i;
        final sample =
            sampleIndex < samples.length ? samples[sampleIndex] : 0.0;
        input[i] = sample * window[i];
      }

      final spectrum = fft.realFft(input);
      final powerBins = List<double>.filled(fftSize ~/ 2 + 1, 0);
      for (var k = 0; k < powerBins.length; k += 1) {
        final value = spectrum[k];
        powerBins[k] = value.x * value.x + value.y * value.y;
      }

      for (var melBin = 0; melBin < melBins; melBin += 1) {
        var energy = 0.0;
        for (var k = 0; k < powerBins.length; k += 1) {
          energy += powerBins[k] * filterBank[melBin][k];
        }
        mel[melBin][frame] = 10.0 * log(1.0 + energy) / ln10;
      }
    }

    return mel;
  }

  static List<List<double>> _createMelFilterBank({
    required int sampleRate,
    required int fftSize,
    required int melBins,
    required double minFreq,
    required double maxFreq,
  }) {
    double hzToMel(double hz) => 2595.0 * log(1.0 + hz / 700.0) / ln10;
    double melToHz(double mel) => 700.0 * (pow(10.0, mel / 2595.0) - 1.0);

    final nyquist = sampleRate / 2;
    final clampedMinFreq = minFreq.clamp(0.0, nyquist).toDouble();
    final clampedMaxFreq = maxFreq.clamp(clampedMinFreq, nyquist).toDouble();
    final powerBins = fftSize ~/ 2 + 1;
    final minMel = hzToMel(clampedMinFreq);
    final maxMel = hzToMel(clampedMaxFreq);
    final melPoints = List<double>.generate(
      melBins + 2,
      (index) => minMel + (maxMel - minMel) * index / (melBins + 1),
    );
    final binPoints =
        melPoints
            .map(melToHz)
            .map(
              (hz) => _clampInt(
                (((fftSize + 1) * hz) / sampleRate).floor(),
                lower: 0,
                upper: powerBins - 1,
              ),
            )
            .toList();
    final filters = List.generate(
      melBins,
      (_) => List<double>.filled(powerBins, 0),
    );

    for (var melIndex = 1; melIndex <= melBins; melIndex += 1) {
      final left = binPoints[melIndex - 1];
      final center = max(binPoints[melIndex], left + 1);
      final right = min(max(binPoints[melIndex + 1], center + 1), powerBins);

      for (var k = left; k < center && k < powerBins; k += 1) {
        filters[melIndex - 1][k] = (k - left) / (center - left);
      }
      for (var k = center; k < right && k < powerBins; k += 1) {
        filters[melIndex - 1][k] = (right - k) / (right - center);
      }
    }

    return filters;
  }

  static int _clampInt(int value, {required int lower, required int upper}) {
    if (value < lower) {
      return lower;
    }
    if (value > upper) {
      return upper;
    }
    return value;
  }
}
