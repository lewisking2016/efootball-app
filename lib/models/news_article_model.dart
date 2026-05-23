class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String sourceName;
  final DateTime publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No description available',
      url: json['url'] ?? '',
      imageUrl:
          json['urlToImage'] ??
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/EFootball_logo.svg/512px-EFootball_logo.svg.png',
      sourceName: json['source']?['name'] ?? 'Unknown Source',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
