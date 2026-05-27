import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/features/articles/data/educational_articles_seed.dart';

void main() {
  test('educational articles seed has trusted content links', () {
    expect(educationalArticlesSeed, hasLength(3));
    expect(
      educationalArticlesSeed.map((item) => item.title).toList(),
      containsAll(<String>[
        'Understanding Lung Health',
        'Air Quality & Your Lungs',
        'Quitting Smoking Guide',
      ]),
    );

    for (final item in educationalArticlesSeed) {
      expect(item.url, startsWith('https://'));
      expect(item.description, isNotEmpty);
    }
  });
}
