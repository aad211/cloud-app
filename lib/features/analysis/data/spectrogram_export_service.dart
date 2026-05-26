import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native_storage_stub.dart'
    if (dart.library.io) 'native_storage_io.dart'
    as native_storage;

class SpectrogramExportResult {
  const SpectrogramExportResult({
    required this.spectrogramFilePath,
    required this.storageBackend,
    this.repoMirrorPath,
  });

  final String spectrogramFilePath;
  final String storageBackend;
  final String? repoMirrorPath;
}

class SpectrogramExportService {
  SpectrogramExportService({
    bool? isWeb,
    Future<String> Function()? getDocumentsDirectoryPath,
    Future<SharedPreferences> Function()? getSharedPreferences,
    Future<bool> Function(String key, String value)? saveBrowserValue,
    Future<String?> Function()? resolveRepoRootDirectoryPath,
    Future<void> Function(String path, Uint8List bytes)? writeBytesToFile,
    Future<Uint8List> Function(List<List<double>> melSpectrogram)?
    renderPngBytes,
  }) : _isWeb = isWeb ?? kIsWeb,
       _getDocumentsDirectoryPath = getDocumentsDirectoryPath,
       _getSharedPreferences = getSharedPreferences,
       _saveBrowserValue = saveBrowserValue,
       _resolveRepoRootDirectoryPath = resolveRepoRootDirectoryPath,
       _writeBytesToFile = writeBytesToFile,
       _renderPngBytes = renderPngBytes;

  final bool _isWeb;
  final Future<String> Function()? _getDocumentsDirectoryPath;
  final Future<SharedPreferences> Function()? _getSharedPreferences;
  final Future<bool> Function(String key, String value)? _saveBrowserValue;
  final Future<String?> Function()? _resolveRepoRootDirectoryPath;
  final Future<void> Function(String path, Uint8List bytes)? _writeBytesToFile;
  final Future<Uint8List> Function(List<List<double>> melSpectrogram)?
  _renderPngBytes;

  Future<SpectrogramExportResult> export({
    required String analysisId,
    required List<List<double>> melSpectrogram,
  }) async {
    final safeAnalysisId = Uri.encodeComponent(analysisId);
    final pngBytes = await (_renderPngBytes ?? _defaultRenderPngBytes)(
      melSpectrogram,
    );

    if (_isWeb) {
      final key = 'spectrogram/$safeAnalysisId';
      final encodedBytes = base64Encode(pngBytes);
      final didSave =
          _saveBrowserValue != null
              ? await _saveBrowserValue(key, encodedBytes)
              : await _saveToSharedPreferences(key, encodedBytes);
      if (!didSave) {
        throw StateError('Failed to persist spectrogram in browser storage.');
      }
      return SpectrogramExportResult(
        spectrogramFilePath: key,
        storageBackend: 'browser',
      );
    }

    final documentsDirectoryPath =
        _getDocumentsDirectoryPath != null
            ? await _getDocumentsDirectoryPath!()
            : await native_storage.getApplicationDocumentsDirectoryPath();
    final nativePath = native_storage.joinPath([
      documentsDirectoryPath,
      'spectrograms',
      '$safeAnalysisId.png',
    ]);
    await (_writeBytesToFile ?? native_storage.writeBytesToFile)(
      nativePath,
      pngBytes,
    );

    String? repoMirrorPath;
    final repoRootPath =
        _resolveRepoRootDirectoryPath != null
            ? await _resolveRepoRootDirectoryPath!()
            : await native_storage.resolveRepoRootDirectoryPath();
    if (repoRootPath != null) {
      final candidatePath = native_storage.joinPath([
        repoRootPath,
        'analysis_outputs',
        '$safeAnalysisId.png',
      ]);
      try {
        await (_writeBytesToFile ?? native_storage.writeBytesToFile)(
          candidatePath,
          pngBytes,
        );
        repoMirrorPath = candidatePath;
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'spectrogram_export_service',
            context: ErrorDescription(
              'Failed to persist spectrogram repo mirror.',
            ),
          ),
        );
      }
    }

    return SpectrogramExportResult(
      spectrogramFilePath: nativePath,
      storageBackend: 'native',
      repoMirrorPath: repoMirrorPath,
    );
  }

  Future<bool> _saveToSharedPreferences(String key, String value) async {
    final prefs =
        _getSharedPreferences != null
            ? await _getSharedPreferences()
            : await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<Uint8List> _defaultRenderPngBytes(
    List<List<double>> melSpectrogram,
  ) async {
    final height = melSpectrogram.isEmpty ? 1 : melSpectrogram.length;
    final width = melSpectrogram.fold<int>(
      1,
      (maxWidth, row) => row.length > maxWidth ? row.length : maxWidth,
    );
    final values = <double>[];
    for (final row in melSpectrogram) {
      for (final value in row) {
        if (value.isFinite) {
          values.add(value);
        }
      }
    }
    final minValue = values.isEmpty ? 0.0 : values.reduce(_minDouble);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(_maxDouble);
    final range = maxValue - minValue;
    final pixels = Uint8List(width * height * 4);

    for (var y = 0; y < height; y += 1) {
      final melRow = height - 1 - y;
      final row =
          melRow < melSpectrogram.length
              ? melSpectrogram[melRow]
              : const <double>[];
      for (var x = 0; x < width; x += 1) {
        final rawValue = x < row.length && row[x].isFinite ? row[x] : minValue;
        final normalized =
            range <= 0 ? 0.0 : ((rawValue - minValue) / range).clamp(0.0, 1.0);
        final color = _infernoColor(normalized);
        final offset = (y * width + x) * 4;
        pixels[offset] = color.$1;
        pixels[offset + 1] = color.$2;
        pixels[offset + 2] = color.$3;
        pixels[offset + 3] = 255;
      }
    }

    final image = await _decodeImageFromPixels(
      pixels,
      width: width,
      height: height,
    );
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode spectrogram PNG bytes.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<ui.Image> _decodeImageFromPixels(
    Uint8List pixels, {
    required int width,
    required int height,
  }) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  (int, int, int) _infernoColor(double value) {
    const palette = <(double, int, int, int)>[
      (0.0, 0, 0, 4),
      (0.13, 31, 12, 72),
      (0.25, 85, 15, 109),
      (0.38, 136, 34, 106),
      (0.5, 186, 54, 85),
      (0.63, 227, 89, 51),
      (0.75, 249, 140, 10),
      (0.88, 252, 195, 65),
      (1.0, 252, 255, 164),
    ];

    for (var index = 1; index < palette.length; index += 1) {
      final lower = palette[index - 1];
      final upper = palette[index];
      if (value <= upper.$1) {
        final span = upper.$1 - lower.$1;
        final t = span == 0 ? 0.0 : (value - lower.$1) / span;
        return (
          _lerpChannel(lower.$2, upper.$2, t),
          _lerpChannel(lower.$3, upper.$3, t),
          _lerpChannel(lower.$4, upper.$4, t),
        );
      }
    }

    final last = palette.last;
    return (last.$2, last.$3, last.$4);
  }

  int _lerpChannel(int a, int b, double t) =>
      (a + ((b - a) * t)).round().clamp(0, 255);

  double _minDouble(double a, double b) => a < b ? a : b;

  double _maxDouble(double a, double b) => a > b ? a : b;
}

final spectrogramExportServiceProvider = Provider<SpectrogramExportService>(
  (ref) => SpectrogramExportService(),
);
