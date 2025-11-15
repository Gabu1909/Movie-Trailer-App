import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../providers/auth_provider.dart';
import '../../utils/ui_helpers.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for editable fields
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
    // Initialize controllers
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data from AuthProvider after context is available
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
    // Load current user data from AuthProvider
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
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update profile via AuthProvider
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
        // Pop back to profile screen with success message
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, 'Failed to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF12002F), Color(0xFF3A0CA3), Color(0xFF7209B7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      // Avatar
                      _buildAvatar(),
                      const SizedBox(height: 30),

                      // Full Name (editable)
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Username (editable)
                      _buildTextField(
                        controller: _usernameController,
                        hintText: 'Username',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter username';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Only letters, numbers and underscore';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email (editable)
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      _buildPhoneField(),
                      const SizedBox(height: 20),

                      // Gender
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

                      // Country
                      _buildDropdownField(
                        hintText: 'Country/Region',
                        value: _selectedCountry,
                        items: [
                          'Vietnam',
                          'United States',
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

                      // Update Button
                      _buildUpdateButton(context),
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

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Save image to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedImage =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          _profileImageUrl = savedImage.path;
        });

        if (mounted) {
          UIHelpers.showSuccessSnackBar(
              context, 'Image selected successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(context, 'Failed to pick image: $e');
      }
    }
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2B124C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading:
                      const Icon(Icons.photo_camera, color: Colors.pinkAccent),
                  title: const Text('Take Photo',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: Colors.pinkAccent),
                  title: const Text('Choose from Gallery',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.white70),
                  title: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Avatar widget
  Widget _buildAvatar() {
    // Default avatar if no image
    ImageProvider avatarImage;

    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      avatarImage = const NetworkImage('https://i.pravatar.cc/150?img=12');
    } else if (_profileImageUrl!.startsWith('http')) {
      avatarImage = NetworkImage(_profileImageUrl!);
    } else {
      avatarImage = FileImage(File(_profileImageUrl!));
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: avatarImage,
            backgroundColor: Colors.white24,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _showImagePickerOptions,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF12002F), width: 2),
                ),
                padding: const EdgeInsets.all(6),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
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
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  // Widget tùy chỉnh cho SĐT
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        // Validate Vietnamese phone format (9-11 digits)
        if (!RegExp(r'^[0-9]{9,11}$').hasMatch(value)) {
          return 'Invalid phone number (9-11 digits)';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Phone Number',
        hintStyle: const TextStyle(color: Colors.white70),
        // Tạo prefixIcon tùy chỉnh với cờ và mũi tên
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Text('🇻🇳', style: TextStyle(fontSize: 24)),
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
    // Ensure value is valid or null
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
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

  // Update button
  Widget _buildUpdateButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfileData,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        disabledBackgroundColor: Colors.red.withOpacity(0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Update',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
