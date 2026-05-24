class ArticleRecord {
  const ArticleRecord({
    required this.name,
    required this.icon,
    required this.description,
    required this.symptoms,
  });

  final String name;
  final String icon;
  final String description;
  final List<String> symptoms;
}
