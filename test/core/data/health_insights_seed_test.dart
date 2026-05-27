import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/core/data/health_insights_seed.dart';

void main() {
  test('contains exactly 3 health insights', () {
    expect(healthInsightsSeed.length, 3);
  });

  test('all insights have https URLs and non-empty content', () {
    for (final insight in healthInsightsSeed) {
      expect(insight.title.trim().isNotEmpty, isTrue);
      expect(insight.description.trim().isNotEmpty, isTrue);
      expect(insight.url.startsWith('https://'), isTrue);
    }
  });
}
