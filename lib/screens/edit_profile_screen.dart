import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Thêm các controllers mới
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // Biến trạng thái cho Dropdown
  String? _selectedGender = 'Male';
  String? _selectedCountry = 'Viet Nam';

  @override
  void initState() {
    super.initState();
    // Khởi tạo các controller trống trước
    _nameController = TextEditingController();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    // Tải dữ liệu đã lưu để điền vào các controller
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text =
          prefs.getString('profile_name') ?? 'Andrew Ainsley';
      _nicknameController.text =
          prefs.getString('profile_nickname') ?? 'Andrew';
      _emailController.text =
          prefs.getString('profile_email') ?? 'andrew_ainsley@yourdomain.com';
      _phoneController.text =
          prefs.getString('profile_phone') ?? '+84 111 467 378 399';
      _selectedGender = prefs.getString('profile_gender') ?? 'Male';
      _selectedCountry = prefs.getString('profile_country') ?? 'Viet Nam';
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_nickname', _nicknameController.text);
    await prefs.setString('profile_email', _emailController.text);
    await prefs.setString('profile_phone', _phoneController.text);
    if (_selectedGender != null) {
      await prefs.setString('profile_gender', _selectedGender!);
    }
    if (_selectedCountry != null) {
      await prefs.setString('profile_country', _selectedCountry!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Nền gradient đồng nhất (giữ nguyên)
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // 1. Thêm Avatar
                    _buildAvatar(),
                    const SizedBox(height: 30),

                    // 2. Các trường thông tin
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nicknameController,
                      hintText: 'Nickname',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      suffixIcon: Icon(Icons.check_circle_outline,
                          color: Colors.white70, size: 20),
                    ),
                    const SizedBox(height: 20),
                    // 3. Trường số điện thoại tùy chỉnh
                    _buildPhoneField(),
                    const SizedBox(height: 20),
                    // 4. Trường Dropdown cho Giới tính
                    _buildDropdownField(
                      hintText: 'Gender',
                      value: _selectedGender,
                      items: ['Male', 'Female', 'Other'],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // 5. Trường Dropdown cho Quốc gia
                    _buildDropdownField(
                      hintText: 'Country/Region',
                      value: _selectedCountry,
                      items: [
                        'United States',
                        'Vietnam',
                        'Canada',
                        'United Kingdom'
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    // 6. Nút Cập nhật (Update)
                    _buildUpdateButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    // Giữ nguyên AppBar
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          const Text(
            'Edit Profile',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Widget cho Avatar
  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundImage:
                NetworkImage('https://i.pravatar.cc/150?img=12'), // Ảnh mẫu
            backgroundColor: Colors.white24,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red, // Màu nút edit
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF12002F), width: 2),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(6),
            ),
          )
        ],
      ),
    );
  }

  // Widget TextField đã cập nhật (bỏ prefix, dùng hintText)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText, // Dùng hintText thay cho labelText
        hintStyle: const TextStyle(color: Colors.white70),
        suffixIcon: suffixIcon,
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

  // Widget tùy chỉnh cho SĐT
  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Phone Number',
        hintStyle: const TextStyle(color: Colors.white70),
        // Tạo prefixIcon tùy chỉnh với cờ và mũi tên
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            // TODO: Thay thế bằng ảnh cờ thật
            const Text('🇺🇸', style: TextStyle(fontSize: 24)),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
            Container(
              width: 1,
              height: 24,
              color: Colors.white30,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
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

  // Widget cho Dropdown
  Widget _buildDropdownField({
    required String hintText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF2B124C), // Màu nền của menu
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
      ),
    );
  }

  // Nút Update (thay cho Save)
  Widget _buildUpdateButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _saveProfileData(); // Save data
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Profile updated successfully!',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          backgroundColor: Colors.white,
        ));
        context.pop();
      },
      // Bỏ icon, đổi text và màu
      child: const Text('Update',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // Đổi màu thành đỏ
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
