import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/app/app.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';

import 'test_helpers/fake_local_storage_service.dart';

void main() {
  testWidgets('boots into splash screen showing CLOUD', (tester) async {
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
  });
}
