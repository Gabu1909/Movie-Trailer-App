import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../explore_news_movie/movie_news_section.dart';
import '../../api/api_constants.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allArticles = [];
  List<dynamic> _filteredArticles = [];
  bool _isLoading = true;
  String _error = '';

  late AnimationController _bgController;
  late Animation<Alignment> _beginAlignmentAnimation;
  late Animation<Alignment> _endAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _fetchMovieNews();
    _searchController.addListener(_filterArticles);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _beginAlignmentAnimation =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight)
            .animate(_bgController);
    _endAlignmentAnimation =
        AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft)
            .animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _searchController.removeListener(_filterArticles);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMovieNews() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiNewsConstants.baseUrl}/everything?q=movie&language=en&sortBy=publishedAt&apiKey=${ApiNewsConstants.apiKey}'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final articles = (data['articles'] as List<dynamic>).where((article) {
          final url = article['url'];
          final imageUrl = article['urlToImage'];
          return url != null &&
              imageUrl != null &&
              imageUrl is String &&
              imageUrl.isNotEmpty;
        }).toList();
        if (mounted) {
          setState(() {
            _allArticles = articles;
            _filteredArticles = articles;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterArticles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredArticles = _allArticles.where((article) {
        final title = (article['title'] as String? ?? '').toLowerCase();
        return title.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF12002F),
                  Color(0xFF3A0CA3),
                  Color(0xFF7209B7),
                ],
                begin: _beginAlignmentAnimation.value,
                end: _endAlignmentAnimation.value,
              ),
            ),
            child: child,
          ),
        );
      },
      child: RefreshIndicator(
        onRefresh: () => _fetchMovieNews(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              pinned: true,
              title: const Text(
                'Explore Movies',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by title...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              )
            else if (_filteredArticles.isEmpty &&
                _searchController.text.isNotEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No articles found.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              )
            else
              MovieNewsSection(articles: _filteredArticles),
          ],
        ),
      ),
    );
  }
}
