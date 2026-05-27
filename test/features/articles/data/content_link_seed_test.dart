import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/features/articles/data/articles_seed.dart';
import 'package:cloud_app/features/articles/data/news_seed.dart';

void main() {
  test('all disease records expose valid https URL', () {
    expect(articleSeed, isNotEmpty);
    for (final item in articleSeed) {
      expect(item.url.startsWith('https://'), isTrue);
    }
  });

  test('all news records expose valid https URL', () {
    expect(newsSeed, isNotEmpty);
    for (final item in newsSeed) {
      expect(item.url.startsWith('https://'), isTrue);
    }
  });
}
