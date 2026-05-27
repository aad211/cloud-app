import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/core/models/health_insight_record.dart';

void main() {
  test('creates a health insight record with all fields', () {
    const insight = HealthInsightRecord(
      emoji: '🫁',
      title: 'Understanding COPD',
      description: 'Learn about chronic obstructive pulmonary disease',
      url:
          'https://www.who.int/news-room/fact-sheets/detail/chronic-obstructive-pulmonary-disease-(copd)',
    );

    expect(insight.emoji, '🫁');
    expect(insight.title, 'Understanding COPD');
    expect(insight.url.startsWith('https://'), isTrue);
  });
}
