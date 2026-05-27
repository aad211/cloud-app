import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_app/core/storage/local_storage_service.dart';

import 'app.dart';

Future<void> bootstrap() async {
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(
          SharedPrefsLocalStorageService(prefs),
        ),
      ],
      child: const CloudApp(),
    ),
  );
}
