import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.markdownFileName,
  });

  final String title;
  final String markdownFileName;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/articles/$markdownFileName';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('We could not load this article. Please try again later.'),
              ),
            );
          }

          final data = snapshot.data?.trim();
          if (data == null || data.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('This article is currently unavailable.'),
              ),
            );
          }

          final markdownString = _normalizeMarkdown(data);

          return Markdown(
            data: markdownString,
            padding: const EdgeInsets.all(16),
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              p: const TextStyle(fontSize: 16, height: 1.4),
              listBullet: const TextStyle(fontSize: 16),
              blockSpacing: 16,
            ),
            imageBuilder: (uri, title, alt) {
              return Image.asset(
                'assets/articles/${uri.path}',
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }
}

String _normalizeMarkdown(String raw) {
  final normalizedLineEndings = raw.replaceAll('\r\n', '\n');
  final unescaped = normalizedLineEndings.replaceAllMapped(
    RegExp(r'\\([#*_`~>\-\[\]\(\){}!+\.])'),
    (match) => match.group(1)!,
  );
  return unescaped;
}
