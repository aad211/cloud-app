import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/features/onboarding/presentation/splash_screen.dart';

import '../../test_helpers/fake_local_storage_service.dart';
import 'package:cloud_app/core/storage/local_storage_service.dart';

Widget _buildSplash() {
  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWithValue(FakeLocalStorageService()),
    ],
    child: const MaterialApp(home: SplashScreen()),
  );
}

void main() {
  testWidgets('renders react parity cloud branding on gradient background', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSplash());

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('CLOUD'), findsOneWidget);
    expect(find.text('Cough Lung Observation\n& Diagnosis'), findsOneWidget);

    final decoratedBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SplashScreen),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, const [AppColors.navy, AppColors.blue]);
  });

  testWidgets('does not wrap branding in a translucent panel', (tester) async {
    await tester.pumpWidget(_buildSplash());

    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration as BoxDecoration;
        return decoration.color == Colors.white.withValues(alpha: 0.06) &&
            decoration.borderRadius == BorderRadius.circular(32);
      }),
      findsNothing,
    );
  });

  testWidgets('uses direct SVG branding without CloudLogo wrapper', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSplash());

    final svgFinder = find.byType(SvgPicture);
    expect(svgFinder, findsOneWidget);
    final logo = tester.widget<SvgPicture>(svgFinder);
    expect(logo.width, 120);
    expect(logo.height, 120);
    expect(
      logo.colorFilter,
      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'CloudLogo',
      ),
      findsNothing,
    );
  });
}
