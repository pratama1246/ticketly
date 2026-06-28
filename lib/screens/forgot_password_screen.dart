import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../service/auth_service.dart';
import 'verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleConfirmEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    final result = await AuthService.forgotPassword(email);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Kode verifikasi telah dikirim!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate to verification screen with email parameter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(email: email),
          ),
        );
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
    super.dispose();
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
                    'Lupa Kata Sandi',
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
                    'Masukkan email Anda untuk menerima kode verifikasi.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Illustration (from Figma, assets/images/forgot_password_illustration.png)
                Center(
                  child: Image.asset(
                    'assets/images/forgot_password_illustration.png',
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon container in case the asset is missing
                      return Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.vpn_key_outlined,
                          size: 80,
                          color: AppColors.bluePrimary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

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
                const SizedBox(height: 32),

                // Confirmation Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirmEmail,
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
                            'Konfirmasi Email',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
