import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm import cho SystemSound
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/actor_detail.dart';
import '../models/movie.dart'; // Import Movie model

class ActorDetailScreen extends StatefulWidget {
  final int actorId;

  const ActorDetailScreen({super.key, required this.actorId});

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<ActorDetail> _actorDetailFuture;
  late TabController _tabController;
  bool _isBioExpanded = false;

  @override
  void initState() {
    super.initState();
    _actorDetailFuture = ApiService().getActorDetails(widget.actorId);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat.yMMMMd().format(dateTime); // e.g., January 1, 1990
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B124C),
      body: FutureBuilder<ActorDetail>(
          future: _actorDetailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: Text('Actor not found',
                      style: TextStyle(color: Colors.white)));
            }

            final actor = snapshot.data!;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: const Color(0xFF3A0CA3),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(actor.name,
                        style: const TextStyle(shadows: [
                          Shadow(blurRadius: 4, color: Colors.black87)
                        ])),
                    centerTitle: true,
                    background: actor.profilePath != null
                        ? CachedNetworkImage(
                            imageUrl:
                                '${ApiConstants.imageBaseUrlOriginal}${actor.profilePath}',
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.3),
                            colorBlendMode: BlendMode.darken,
                          )
                        : Container(color: Colors.grey[800]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(actor),
                        const SizedBox(height: 24),
                        _buildBiographySection(actor),
                        const SizedBox(height: 16),
                        _buildCreditsSection(actor),
                      ],
                    ),
                  ),
                )
              ],
            );
          }),
    );
  }

  Widget _buildInfoSection(ActorDetail actor) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildInfoItem(Icons.cake, 'Birthday', _formatDate(actor.birthday)),
        _buildInfoItem(
            Icons.location_on, 'Place of Birth', actor.placeOfBirth ?? 'N/A'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _buildBiographySection(ActorDetail actor) {
    if (actor.biography == null || actor.biography!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Biography',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          actor.biography!,
          style: const TextStyle(color: Colors.white70, height: 1.5),
          maxLines: _isBioExpanded ? null : 6,
          overflow: TextOverflow.fade,
        ),
        InkWell(
          onTap: () {
            SystemSound.play(SystemSoundType.click);
            setState(() => _isBioExpanded = !_isBioExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_isBioExpanded ? 'Show Less' : 'Read More',
                style: const TextStyle(
                    color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsSection(ActorDetail actor) {
    final hasMovies = actor.movieCredits.isNotEmpty;
    final hasTvShows = actor.tvCredits.isNotEmpty;

    if (!hasMovies && !hasTvShows) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
        SizedBox(
          height: 240, // Tăng chiều cao để chứa cả tab bar
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreditsList(context, actor.movieCredits),
              _buildCreditsList(context, actor.tvCredits),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsList(BuildContext context, List<Movie> credits) {
    if (credits.isEmpty) {
      return const Center(
          child: Text('No credits found.',
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, right: 16),
      scrollDirection: Axis.horizontal,
      itemCount: credits.length,
      itemBuilder: (context, index) {
        final credit = credits[index];
        return Container(
          width: 140,
          margin: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            // No haptic/sound here, as it navigates to another screen which might have its own feedback
            onTap: () {
              context.push('/movie/${credit.id}');
            },
            // Tạm thời dùng Container để hiển thị poster, vì MovieCard cần context.push
            // mà chúng ta đã có ở trên.
            child: CachedNetworkImage(
              imageUrl: '${ApiConstants.imageBaseUrl}${credit.posterPath}',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
