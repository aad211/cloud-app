import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';

import '../test_helpers/fake_local_storage_service.dart';

void main() {
  testWidgets('shows splash inside the centered mobile frame', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            FakeLocalStorageService(),
          ),
        ],
        child: const OhokApp(),
      ),
    );

    await tester.pump();

    expect(find.text('CLOUD'), findsOneWidget);
    expect(find.byKey(const Key('mobile-frame')), findsOneWidget);
  });
}
