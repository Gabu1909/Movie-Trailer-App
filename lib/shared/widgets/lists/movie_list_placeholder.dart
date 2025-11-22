import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../cards/movie_card_placeholder.dart';

class MovieListPlaceholder extends StatelessWidget {
  const MovieListPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 24,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, 
                itemBuilder: (context, index) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: MovieCardPlaceholder(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
