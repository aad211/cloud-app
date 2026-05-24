import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> bootstrap() async {
  runApp(const ProviderScope(child: OhokApp()));
}
