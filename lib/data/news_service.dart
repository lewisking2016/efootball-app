import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/news_article_model.dart';

class NewsService {
  static const String _apiKey = 'c26ad0089aef406292a27f9b392705e6';
  static const String _baseUrl = 'https://newsapi.org/v2';

  Future<List<NewsArticle>> fetchTopFootballNews() async {
    try {
      // Fetching top soccer/football news from UK sources for EPL relevance
      // Using corsproxy.io because NewsAPI blocks direct localhost/browser requests on free tier
      final encodedUrl = Uri.encodeComponent('$_baseUrl/top-headlines?country=gb&category=sports&q=football&apiKey=$_apiKey');
      final url = Uri.parse('https://corsproxy.io/?$encodedUrl');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok' && data['articles'] != null) {
          final List articles = data['articles'];
          return articles
              .where((article) => article['title'] != null && article['urlToImage'] != null)
              .map((article) => NewsArticle.fromJson(article))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching news: $e");
      return [];
    }
  }

  Future<List<NewsArticle>> fetchEverythingFootball() async {
    try {
      // Broader search for European football
      final encodedUrl = Uri.encodeComponent('$_baseUrl/everything?q=premier league OR champions league football&language=en&sortBy=publishedAt&apiKey=$_apiKey');
      final url = Uri.parse('https://corsproxy.io/?$encodedUrl');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok' && data['articles'] != null) {
          final List articles = data['articles'];
          return articles
              .where((article) => article['title'] != null && article['urlToImage'] != null)
              .map((article) => NewsArticle.fromJson(article))
              .toList();
        }
      }
      return [];
    } catch (e) {
       debugPrint("Error fetching news: $e");
      return [];
    }
  }
}
