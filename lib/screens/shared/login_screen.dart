import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Điều hướng đến trang chủ nếu đăng nhập thành công
      if (mounted) context.go('/home');
    } catch (error) {
      // Giả sử lỗi 'user-not-found' được trả về khi email chưa đăng ký.
      if (error.toString().toLowerCase().contains('user not found')) {
        _showRegisterDialog();
      } else {
        // Hiển thị thông báo lỗi chung cho các trường hợp khác (sai mật khẩu, v.v.)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông báo'),
        content: const Text(
            'Tài khoản này chưa được đăng ký. Bạn có muốn tạo tài khoản mới không?'),
        actions: <Widget>[
          TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Đăng ký'),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/register');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh nền blur tím
            Image.asset('assets/background.png', fit: BoxFit.cover),
            Container(
              color: Colors.black.withOpacity(0.5),
            ),

            // Form đăng nhập
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 20,
                            color: Colors.pinkAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                              controller: _emailController,
                              hint: 'Email',
                              icon: Icons.email),
                          const SizedBox(height: 20),
                          _buildInputField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock,
                              obscure: true),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : _buildGlowButton(
                                  text: 'Login',
                                  onPressed: _login,
                                ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text(
                              "Don't have an account? Sign up",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $hint' : null,
    );
  }

  Widget _buildGlowButton(
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7209B7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
        elevation: 10,
        shadowColor: Colors.pinkAccent.withOpacity(0.6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
