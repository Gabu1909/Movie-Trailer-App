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
  int _selectedChipIndex = 0;
  final List<String> _chipLabels = ['General', 'Account', 'Service', 'Video'];

  final Map<String, List<FaqItem>> _allFaqs = {
    'General': [
      FaqItem(
        question: 'What is PuTa Movies?',
        answer:
            'PuTa Movies is your ultimate destination for streaming movies and TV shows. We offer a vast library of content available on demand.',
        isExpanded: true,
      ),
      FaqItem(
        question: 'Is PuTa Movies free to use?',
        answer:
            'Yes, PuTa Movies is completely free to use. Enjoy our extensive library of movies and TV shows without any subscription fees.',
      ),
    ],
    'Account': [
      FaqItem(
        question: 'How do I reset my password?',
        answer:
            'Go to Profile > Security > Change Password. If you forgot it, use the "Forgot Password" link on the login screen.',
      ),
      FaqItem(
        question: 'Can I change my email address?',
        answer:
            'Currently, email addresses are linked to your account ID and cannot be changed directly. Please contact support.',
      ),
    ],
    'Service': [
      FaqItem(
        question: 'How does the recommendation system work?',
        answer:
            'Our AI analyzes your viewing history and liked movies to suggest content that fits your taste.',
      ),
    ],
    'Video': [
      FaqItem(
        question: 'How can I change video quality?',
        answer:
            'Tap the settings icon in the video player or go to App Settings > Download Quality to set default preferences.',
      ),
      FaqItem(
        question: 'Why is my video buffering?',
        answer:
            'Buffering is usually caused by slow internet. Check your connection or try lowering the video quality.',
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? const LinearGradient(
                      colors: [
                          Color(0xFF12002F),
                          Color(0xFF2A0955),
                          Color(0xFF12002F)
                        ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFaqTab(),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Help Center',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: Colors.pinkAccent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'FAQ'),
          Tab(text: 'Contact Us'),
        ],
      ),
    );
  }

  // --- FAQ TAB ---

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

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chipLabels.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedChipIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChipIndex = index;
                _filteredFaqs = _allFaqs[_chipLabels[index]] ?? [];
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.pinkAccent
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.pinkAccent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                _chipLabels[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search Topics',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: const Icon(Icons.tune_rounded, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    return Column(
      children: _filteredFaqs.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey(item.question),
              initiallyExpanded: item.isExpanded,
              title: Text(
                item.question,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              iconColor: Colors.pinkAccent,
              collapsedIconColor: Colors.white54,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  item.answer,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- CONTACT US TAB ---

  Widget _buildContactUsTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Our team is available 24/7 to assist you.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildContactItem(
            icon: Icons.headset_mic_rounded,
            color: Colors.pinkAccent,
            title: 'Customer Service',
            subtitle: 'Available 24/7',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email_rounded,
            color: Colors.blueAccent,
            title: 'Email Support',
            subtitle: 'support@putamovies.com',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.chat_bubble_rounded,
            color: Colors.greenAccent,
            title: 'Live Chat',
            subtitle: 'Start a conversation',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.web_rounded,
            color: Colors.purpleAccent,
            title: 'Website',
            subtitle: 'www.putamovies.com',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
