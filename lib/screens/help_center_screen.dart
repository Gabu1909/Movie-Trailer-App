import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Dữ liệu mẫu cho FAQ
class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem(
      {required this.question, required this.answer, this.isExpanded = false});
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  // Trạng thái cho chip đang được chọn
  int _selectedChipIndex = 0;
  final List<String> _chipLabels = ['General', 'Account', 'Service', 'Video'];

  // Dữ liệu FAQ được tổ chức theo danh mục
  final Map<String, List<FaqItem>> _allFaqs = {
    'General': [
      FaqItem(
        question: 'What is PuTa Movies?',
        answer:
            'PuTa Movies is your ultimate destination for streaming movies and TV shows. We offer a vast library of content, from the latest blockbusters to timeless classics, available on demand.',
        isExpanded: true,
      ),
      FaqItem(
        question: 'How do I manage my Watchlist?',
        answer:
            'You can add movies to your Watchlist by tapping the bookmark icon on any movie detail page. To remove an item, simply tap the icon again. You can view your full list from the "My List" tab.',
      ),
      FaqItem(
        question: 'Is PuTa Movies free to use?',
        answer:
            'Yes, PuTa Movies is completely free to use. Enjoy our extensive library of movies and TV shows without any subscription fees.',
      ),
    ],
    'Account': [
      FaqItem(
        question: 'How do I create an account?',
        answer:
            'You can create an account by clicking on the "Profile" tab and selecting the "Sign Up" option. Follow the on-screen instructions to complete your registration.',
      ),
      FaqItem(
        question: 'How do I reset my password?',
        answer:
            'If you have forgotten your password, you can reset it by going to the login screen and tapping "Forgot Password". You will receive an email with instructions on how to set a new password.',
      ),
      FaqItem(
        question: 'How can I update my profile information?',
        answer:
            'You can update your name, email, and other personal details by navigating to "Profile" and selecting "Edit Profile".',
      ),
    ],
    'Service': [
      FaqItem(
        question: 'How does the recommendation system work?',
        answer:
            'Our recommendation system analyzes your viewing history and liked movies to suggest content that you might enjoy. The more you watch, the better the recommendations become.',
      ),
      FaqItem(
        question: 'How can I report a problem with the service?',
        answer:
            'If you encounter any issues, please use the "Contact Us" tab in the Help Center. You can reach out to our support team via email or live chat for assistance.',
      ),
    ],
    'Video': [
      FaqItem(
        question: 'Why is the video buffering or not playing?',
        answer:
            'Buffering issues are often caused by a slow or unstable internet connection. Please check your network speed. If the problem persists, try restarting the app or your device.',
      ),
      FaqItem(
        question: 'How can I change the video quality?',
        answer:
            'Video quality options are available in the player settings. You can choose from different resolutions depending on your internet connection and device capabilities.',
      ),
      FaqItem(
        question: 'How do I enable or change subtitles?',
        answer:
            'You can enable, disable, or change the language of subtitles from the video player controls. Look for the subtitle or "CC" icon to access these options.',
      ),
    ],
  };

  late List<FaqItem> _filteredFaqs;

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _allFaqs[_chipLabels[_selectedChipIndex]] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng TabController để quản lý 2 tab
    return DefaultTabController(
      length: 2, // "FAQ" và "Contact us"
      child: Scaffold(
        body: Container(
          // Nền gradient đồng nhất
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF12002F), Color(0xFF3A0CA3), Color(0xFF7209B7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildTabBar(),
                // Nội dung của các Tab
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: FAQ
                      _buildFaqTab(),
                      // Tab 2: Contact Us (Placeholder)
                      _buildContactUsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget AppBar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nút quay lại
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          // Tiêu đề
          const Text(
            'Help Center',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          // Nút menu (ba chấm)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.more_horiz,
                    color: Colors.white70, size: 20),
                onPressed: () {
                  // Action for menu button (e.g., show a popup menu)
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget cho TabBar (FAQ / Contact us)
  Widget _buildTabBar() {
    return const TabBar(
      tabs: [
        Tab(text: 'FAQ'),
        Tab(text: 'Contact us'),
      ],
      labelColor: Colors.pinkAccent, // Màu text của tab được chọn
      unselectedLabelColor: Colors.white70, // Màu text tab không được chọn
      indicatorColor: Colors.pinkAccent, // Màu vạch chân
      indicatorWeight: 3.0,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  // Widget cho nội dung Tab FAQ
  Widget _buildFaqTab() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        _buildCategoryChips(),
        const SizedBox(height: 20),
        _buildSearchBar(),
        const SizedBox(height: 20),
        _buildFaqList(),
      ],
    );
  }

  // Widget cho các Chip lọc
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chipLabels.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedChipIndex == index;
          return ChoiceChip(
            label: Text(_chipLabels[index]),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedChipIndex = selected ? index : 0; // Default to General
                // Cập nhật danh sách FAQ được lọc
                _filteredFaqs = _allFaqs[_chipLabels[_selectedChipIndex]] ?? [];
              });
            },
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.transparent,
            selectedColor: Colors.pinkAccent, // Nền hồng khi được chọn
            shape: const StadiumBorder(
              side: BorderSide(
                color: Colors.pinkAccent, // Viền hồng
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
      ),
    );
  }

  // Widget cho thanh tìm kiếm
  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon:
            const Icon(Icons.tune, color: Colors.white70), // Icon bộ lọc
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
      ),
    );
  }

  // Widget cho danh sách FAQ (dùng ExpansionTile)
  Widget _buildFaqList() {
    return Column(
      children: _filteredFaqs.map((item) {
        return Card(
          color: Colors.white.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias, // Để bo góc nội dung bên trong
          child: ExpansionTile(
            key: PageStorageKey(item.question), // Giữ trạng thái khi cuộn
            initiallyExpanded: item.isExpanded,
            title: Text(
              item.question,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            // Đổi icon mũi tên thành màu đỏ
            iconColor: Colors.pinkAccent,
            collapsedIconColor: Colors.pinkAccent,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                item.answer,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
            onExpansionChanged: (bool expanded) {
              setState(() {
                item.isExpanded = expanded;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  // Widget cho nội dung Tab Contact Us
  Widget _buildContactUsTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need more help? Reach out to us!',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildContactInfoItem(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@putamovies.com',
            onTap: () {
              // TODO: Implement email client launch
            },
          ),
          _buildContactInfoItem(
            icon: Icons.phone,
            title: 'Phone Support',
            subtitle: '+1 (555) 123-4567',
            onTap: () {
              // TODO: Implement phone dialer launch
            },
          ),
          _buildContactInfoItem(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Chat with our support team 24/7',
            onTap: () {
              // TODO: Implement live chat functionality
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Our team is available to assist you with any questions or issues you may have.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.pinkAccent, size: 30),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }
}
