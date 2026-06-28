import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../service/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
      passwordConfirm: confirmPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pendaftaran berhasil! Silakan masuk.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Go back to login screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildSSOButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDefault, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Title
                Center(
                  child: Text(
                    'Daftar',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Center(
                  child: Text(
                    'Silakan daftar untuk memesan tiket event seru.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Email Label
                Row(
                  children: [
                    Text(
                      'Email',
                      style: AppTextStyles.labelStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(' *', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'nama@email.com',
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(255),
                  ],
                ),
                const SizedBox(height: 20),

                // Username Label
                Row(
                  children: [
                    Text(
                      'Nama Pengguna',
                      style: AppTextStyles.labelStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(' *', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 8),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pengguna tidak boleh kosong';
                    }
                    if (value.trim().length < 3) {
                      return 'Nama pengguna minimal 3 karakter';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'username',
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(100),
                  ],
                ),
                const SizedBox(height: 20),

                // Password Label
                Row(
                  children: [
                    Text(
                      'Kata Sandi',
                      style: AppTextStyles.labelStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(' *', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    if (value.length < 8) {
                      return 'Kata sandi minimal 8 karakter';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(128),
                  ],
                ),
                const SizedBox(height: 20),

                // Confirm Password Label
                Row(
                  children: [
                    Text(
                      'Konfirmasi Kata Sandi',
                      style: AppTextStyles.labelStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(' *', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong';
                    }
                    if (value != _passwordController.text) {
                      return 'Konfirmasi kata sandi tidak cocok';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(128),
                  ],
                ),
                const SizedBox(height: 32),

                // Register Button (Pill shape, full width, AppColors.bluePrimary)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Daftar',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Divider "Daftar dengan"
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.borderDefault, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Daftar dengan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.borderDefault, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // SSO Row (Facebook, Google, Apple)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSSOButton(
                      child: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pendaftaran dengan Facebook hanya hiasan')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSSOButton(
                      child: SvgPicture.asset(
                        'assets/icons/google.svg',
                        width: 24,
                        height: 24,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pendaftaran dengan Google hanya hiasan')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildSSOButton(
                      child: const Icon(Icons.apple, color: Colors.black, size: 28),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pendaftaran dengan Apple hanya hiasan')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Back to Login Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                        children: const [
                          TextSpan(text: 'Sudah memiliki Akun? '),
                          TextSpan(
                            text: 'Masuk',
                            style: TextStyle(
                              color: AppColors.bluePrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
