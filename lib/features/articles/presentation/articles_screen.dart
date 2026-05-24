import 'package:flutter/material.dart';
import 'package:ohok_flutter/features/articles/data/articles_seed.dart';
import 'package:ohok_flutter/features/articles/data/news_seed.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  var tab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: tab,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Articles and News'),
          bottom: TabBar(
            onTap: (value) => setState(() => tab = value),
            tabs: const [
              Tab(text: 'Articles'),
              Tab(text: 'News'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final article in articleSeed)
                  ListTile(
                    leading: Text(article.icon),
                    title: Text(article.name),
                    subtitle: Text(article.description),
                  ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final news in newsSeed)
                  ListTile(
                    leading: Text(news.image),
                    title: Text(news.title),
                    subtitle: Text('${news.category} • ${news.date}\n${news.description}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
