import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../api/api_constants.dart';
import '../../models/user_review_with_movie.dart';
import '../../providers/auth_provider.dart';
import '../../providers/my_reviews_provider.dart';
import '../../utils/ui_helpers.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context
            .read<MyReviewsProvider>()
            .loadMyReviews(userId, isRefresh: true);
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<MyReviewsProvider>().fetchMore(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Reviews',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    colors: [
                        Color(0xFF0D0221),
                        Color(0xFF240046),
                        Color(0xFF3A0CA3)
                      ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null),
        child: SafeArea(
          child: Consumer<MyReviewsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent));
              }

              if (provider.error != null) {
                return Center(
                    child: Text(provider.error!,
                        style: const TextStyle(color: Colors.red)));
              }

              if (provider.reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rate_review_outlined,
                          size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        "You haven't written any reviews yet.",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent),
                        child: const Text('Find a movie to review',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                itemCount:
                    provider.reviews.length + (provider.isFetchingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == provider.reviews.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.pinkAccent)),
                    );
                  }
                  final item = provider.reviews[index];
                  return _buildReviewCard(context, item);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, UserReviewWithMovie item) {
    final review = item.review;
    final movie = item.movie;
    String formattedDate = '';
    if (review.createdAt.isNotEmpty) {
      try {
        formattedDate =
            DateFormat.yMMMMd().format(DateTime.parse(review.createdAt));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        context.push('/movie/${movie.id}', extra: {'scrollToMyReview': true});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: '${ApiConstants.imageBaseUrlW500}${movie.posterPath}',
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Container(color: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (review.rating != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(review.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold)),
                        const Text('  •  ',
                            style: TextStyle(color: Colors.white38)),
                      ],
                      Text(formattedDate,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.content,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
