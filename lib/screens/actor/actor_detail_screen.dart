import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Thêm import shimmer
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../api/api_constants.dart';
import '../../models/actor_detail.dart';
import '../../models/cast.dart'; // Import Cast model
import '../../providers/actor_detail_provider.dart';
import '../../widgets/lists/related_movies_list.dart';

class ActorDetailScreen extends StatefulWidget {
  final int actorId;
  final Cast? initialData; // Dữ liệu ban đầu để hiển thị ngay

  const ActorDetailScreen({super.key, required this.actorId, this.initialData});

  @override
  State<ActorDetailScreen> createState() => _ActorDetailScreenState();
}

class _ActorDetailScreenState extends State<ActorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBioExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActorDetailProvider>().fetchActorDetails(widget.actorId);
    });
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ActorDetailProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading(widget.actorId);
          final error = provider.getError(widget.actorId);
          final actor = provider.getActor(widget.actorId);
          final initialData = widget.initialData;

          // Ưu tiên hiển thị dữ liệu chi tiết nếu có
          if (actor != null) {
            return _buildActorDetailContent(context, actor);
          }

          // Nếu không, hiển thị dữ liệu ban đầu (nếu có) trong khi tải
          if (initialData != null) {
            return _buildInitialContent(context, initialData);
          }

          // Nếu đang tải và không có dữ liệu ban đầu, hiển thị placeholder
          if (isLoading && actor == null && initialData == null) {
            return const ActorDetailPlaceholder(); // Giao diện chờ mới
          }

          // Xử lý lỗi hoặc trường hợp không tìm thấy
          return _buildErrorWidget(context, error ?? 'Actor not found.');
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context
                  .read<ActorDetailProvider>()
                  .fetchActorDetails(widget.actorId, forceRefresh: true);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Hàm tính tuổi
  String? _calculateAge(String? birthdayString) {
    if (birthdayString == null || birthdayString.isEmpty) return null;
    try {
      final birthDate = DateTime.parse(birthdayString);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? '$age years old' : null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildActorDetailContent(BuildContext context, ActorDetail actor) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 400.0,
          pinned: true,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              actor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            // Nâng cấp: Thêm hiệu ứng parallax khi cuộn
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      '${ApiConstants.imageBaseUrlOriginal}${actor.profilePath}',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.person, size: 100, color: Colors.grey),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng thông tin thống kê mới
                _buildStatsRow(actor),
                const SizedBox(height: 24),

                _buildInfoTile(
                  icon: Icons.cake_outlined,
                  label: 'Birthday',
                  value: actor.birthday != null
                      ? DateFormat.yMMMMd()
                          .format(DateTime.parse(actor.birthday!))
                      : null,
                ),
                if (actor.placeOfBirth != null &&
                    actor.placeOfBirth!.isNotEmpty)
                  _buildInfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Place of Birth',
                    value: actor.placeOfBirth,
                  ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),

                // Tiểu sử có thể mở rộng
                _buildBiography(actor.biography),
                const SizedBox(height: 24),

                // Tabs cho Movies và TV Shows
              ],
            ),
          ),
        ),
        // Chuyển _buildCreditsTabs ra ngoài SliverToBoxAdapter chính
        ..._buildCreditsTabs(actor),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom),
        ),
      ],
    );
  }

  /// Widget để hiển thị nội dung ban đầu từ model `Cast` trong khi chờ tải.
  Widget _buildInitialContent(BuildContext context, Cast cast) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn
      slivers: [
        SliverAppBar(
          expandedHeight: 400.0,
          pinned: true,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              cast.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (cast.profilePath != null)
                  CachedNetworkImage(
                    imageUrl:
                        '${ApiConstants.imageBaseUrlOriginal}${cast.profilePath}',
                    fit: BoxFit.cover,
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverFillRemaining(child: ActorDetailPlaceholder()),
      ],
    );
  }

  Widget _buildStatsRow(ActorDetail actor) {
    final age = _calculateAge(actor.birthday);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.star_purple500_outlined, 'Popularity',
            actor.popularity.toStringAsFixed(1)),
        if (actor.gender != 0)
          _buildStatItem(
            actor.gender == 1 ? Icons.female : Icons.male,
            'Gender',
            actor.gender == 1 ? 'Female' : 'Male',
          ),
        if (age != null)
          _buildStatItem(Icons.calendar_today_outlined, 'Age', age),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildBiography(String? biography) {
    if (biography == null || biography.isEmpty) {
      return const SizedBox.shrink();
    }
    // Nâng cấp: Bọc nội dung trong một khung để dễ đọc hơn
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Biography',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            biography,
            style: const TextStyle(
                color: Colors.white70, fontSize: 15, height: 1.5),
            maxLines: _isBioExpanded ? null : 4,
            overflow:
                _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          // Chỉ hiển thị nút nếu text đủ dài để cần mở rộng
          if (biography.length > 200)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => _isBioExpanded = !_isBioExpanded),
                child: Text(_isBioExpanded ? 'Show Less' : 'Read More',
                    style: const TextStyle(color: Colors.pinkAccent)),
              ),
            ),
        ],
      ),
    );
  }

  // Widget helper để hiển thị thông tin, sẽ không render nếu value là null
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    // SỬA LỖI: Nếu value là null hoặc rỗng, trả về một widget trống
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.pinkAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sửa đổi: Hàm này giờ trả về một List<Widget> (cụ thể là các slivers)
  List<Widget> _buildCreditsTabs(ActorDetail actor) {
    return [
      SliverToBoxAdapter(
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 280, // Tăng chiều cao để vừa với RelatedMoviesList
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab Movies
              if (actor.movieCredits.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: RelatedMoviesList(
                    title: '', // Bỏ title vì đã có tab
                    items: actor.movieCredits,
                  ),
                )
              else
                _buildEmptyCreditsView('No movies found.'),
              // Tab TV Shows
              if (actor.tvCredits.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: RelatedMoviesList(
                    title: '', // Bỏ title vì đã có tab
                    items: actor.tvCredits,
                  ),
                )
              else
                _buildEmptyCreditsView('No TV shows found.'),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildEmptyCreditsView(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }
}

// Giao diện chờ mới
class ActorDetailPlaceholder extends StatelessWidget {
  const ActorDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Shimmer effect can be added here for a better look
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: Container(
        color: Colors.black,
        child: CustomScrollView(
          physics:
              const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn khi đang loading
          slivers: [
            SliverAppBar(
              expandedHeight: 400.0,
              backgroundColor: Colors.grey[900],
              automaticallyImplyLeading: false, // Hide back button
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPlaceholderBox(height: 50, width: 80),
                        _buildPlaceholderBox(height: 50, width: 80),
                        _buildPlaceholderBox(height: 50, width: 80),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPlaceholderBox(height: 40, width: double.infinity),
                    const SizedBox(height: 12),
                    _buildPlaceholderBox(height: 40, width: double.infinity),
                    const SizedBox(height: 24),
                    _buildPlaceholderBox(height: 20, width: 150),
                    const SizedBox(height: 12),
                    _buildPlaceholderBox(height: 100, width: double.infinity),
                    const SizedBox(height: 24),
                    _buildPlaceholderBox(height: 200, width: double.infinity),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
