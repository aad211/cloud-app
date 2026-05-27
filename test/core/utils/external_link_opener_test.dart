import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/core/utils/external_link_opener.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  testWidgets('returns true when launcher succeeds', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await openExternalLink(
                  context: context,
                  url: 'https://example.com',
                  launch: (_, {required LaunchMode mode}) async => true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Unable to open link'), findsNothing);
  });

  testWidgets('shows snackbar when launcher fails', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await openExternalLink(
                  context: context,
                  url: 'https://example.com',
                  launch: (_, {required LaunchMode mode}) async => false,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Unable to open link'), findsOneWidget);
  });
}
