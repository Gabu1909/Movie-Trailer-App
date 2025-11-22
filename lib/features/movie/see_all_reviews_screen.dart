import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/models/review.dart';

class SeeAllReviewsScreen extends StatelessWidget {
  final String title;
  final List<Review> reviews;

  const SeeAllReviewsScreen({
    super.key,
    required this.title,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0221),
              Color(0xFF240046),
              Color(0xFF3A0CA3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final review = reviews[index];
              String formattedDate = '';
              if (review.createdAt.isNotEmpty) {
                try {
                  final dateTime = DateTime.parse(review.createdAt);
                  formattedDate = DateFormat.yMMMMd().format(dateTime);
                } catch (e) {
                }
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white10,
                          backgroundImage: review.fullAvatarUrl != null
                              ? CachedNetworkImageProvider(
                                  review.fullAvatarUrl!)
                              : null,
                          child: review.fullAvatarUrl == null
                              ? const Icon(Icons.person,
                                  color: Colors.white54, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(review.author,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        if (formattedDate.isNotEmpty)
                          Text(formattedDate,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(review.content,
                        style: const TextStyle(
                            color: Colors.white70, height: 1.5)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
