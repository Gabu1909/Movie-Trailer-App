import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart'; // Nhớ import cái này

import '../../providers/auth_provider.dart';
import '../../utils/ui_helpers.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _profileImageUrl;
  String? _selectedGender;
  String? _selectedCountry;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileImageUrl == null) {
      _loadProfileData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _usernameController.text = user.username;
        _emailController.text = user.email;
        _profileImageUrl = user.profileImageUrl;
        _phoneController.text = user.phone ?? '';
        _selectedGender = user.gender;
        _selectedCountry = user.country;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            profileImageUrl: _profileImageUrl,
            phone: _phoneController.text.trim(),
            gender: _selectedGender,
            country: _selectedCountry,
          );

      if (mounted) {
        context.pop(true);
        UIHelpers.showSuccessSnackBar(context, 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, 'Failed to update profile: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedImage =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() => _profileImageUrl = savedImage.path);
      }
    } catch (e) {
      if (mounted)
        UIHelpers.showErrorSnackBar(context, 'Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              children: [
                const SizedBox(height: 20),

                // 1. Avatar Section
                _buildAvatarSection(),

                const SizedBox(height: 40),

                // 2. Form Fields
                _buildLabel('Full Name'),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Enter your name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                _buildLabel('Username'),
                _buildTextField(
                  controller: _usernameController,
                  hintText: 'Enter username',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 20),

                _buildLabel('Email Address'),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Enter email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                _buildLabel('Phone Number'),
                _buildPhoneField(),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Gender'),
                          _buildDropdownField(
                            hintText: 'Select',
                            value: _selectedGender,
                            items: ['Male', 'Female', 'Other'],
                            onChanged: (v) =>
                                setState(() => _selectedGender = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Country'),
                          _buildDropdownField(
                            hintText: 'Select',
                            value: _selectedCountry,
                            items: ['Vietnam', 'USA', 'UK', 'Japan'],
                            onChanged: (v) =>
                                setState(() => _selectedCountry = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 3. Action Button
                _buildUpdateButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      title: const Text(
        "Edit Profile",
      ),
      centerTitle: true,
    );
  }

  Widget _buildAvatarSection() {
    ImageProvider avatarImage;
    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      avatarImage = const NetworkImage('https://i.pravatar.cc/150?img=12');
    } else if (_profileImageUrl!.startsWith('http')) {
      avatarImage = CachedNetworkImageProvider(_profileImageUrl!);
    } else {
      avatarImage = FileImage(File(_profileImageUrl!));
    }

    return Center(
      child: Stack(
        children: [
          // Glow Effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.pinkAccent, width: 2),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.black26,
              backgroundImage: avatarImage,
            ),
          ),
          // Edit Button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pinkAccent, Colors.purpleAccent],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF12002F), width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'This field is required';
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '000-000-000',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇻🇳', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hintText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : null,
          hint: Text(hintText,
              style: TextStyle(color: Colors.white.withOpacity(0.3))),
          dropdownColor: const Color(0xFF2B124C),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white54),
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Colors.pinkAccent, Colors.purpleAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfileData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Để bo góc đẹp hơn
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1D0B3C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Change Profile Picture',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: Colors.pinkAccent),
                  title: const Text('Take a photo',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: Colors.purpleAccent),
                  title: const Text('Choose from gallery',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
