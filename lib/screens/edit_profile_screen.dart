import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../service/auth_service.dart';
import '../service/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentProfilePic;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentProfilePic,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _profilePicUrl;
  String _fileName = 'Tidak ada file yang dipilih';
  bool _isLoading = false;
  bool _isPhotoChanged = false;

  // Mock URLs for profile pictures
  static const String _mockAvatar1 = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
  static const String _mockAvatar2 = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _profilePicUrl = widget.currentProfilePic.isEmpty ? _mockAvatar1 : widget.currentProfilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _pickImageMock() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Pilih Foto Profil',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(backgroundImage: NetworkImage(_mockAvatar1)),
                title: const Text('Foto Hana 1'),
                onTap: () {
                  Navigator.pop(context, _mockAvatar1);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundImage: NetworkImage(_mockAvatar2)),
                title: const Text('Foto Hana 2'),
                onTap: () {
                  Navigator.pop(context, _mockAvatar2);
                },
              ),
            ],
          ),
        );
      },
    ).then((selectedUrl) {
      if (selectedUrl != null) {
        setState(() {
          _profilePicUrl = selectedUrl;
          _isPhotoChanged = true;
          _fileName = selectedUrl == _mockAvatar1 ? 'hana_avatar_1.jpg' : 'hana_avatar_2.jpg';
        });
      }
    });
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan Email tidak boleh kosong'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Capture context dependent utilities before async gaps to avoid lints and assertion errors
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      List<int>? photoBytes;
      String? photoName;

      // If user selected a new photo, download its bytes to upload to the backend DB
      if (_isPhotoChanged) {
        photoName = _fileName;
        final response = await http.get(Uri.parse(_profilePicUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          photoBytes = response.bodyBytes;
        }
      }

      final result = await AuthService.updateProfile(
        name: newName,
        email: newEmail,
        fotoBytes: photoBytes,
        fotoFileName: photoName,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final updatedUser = result['data'] as Map<String, dynamic>;
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Perubahan profil berhasil disimpan!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Pop immediately without setState(_isLoading = false) to prevent redundant rebuild during pop transitions
        navigator.pop(<String, String>{
          'name': (updatedUser['username'] as String?) ?? newName,
          'email': (updatedUser['email'] as String?) ?? newEmail,
          'profilePic': (updatedUser['foto'] as String?) ?? _profilePicUrl,
        });
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan perubahan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _profilePicUrl.isNotEmpty && _profilePicUrl.startsWith('http');

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ganti Foto label
            Text(
              'Ganti Foto',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            // Ganti Foto Row
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.borderDefault,
                  backgroundImage: hasImage ? NetworkImage(ApiService.normalizeImageUrl(_profilePicUrl)) : null,
                  child: !hasImage ? const Icon(Icons.person, size: 30, color: AppColors.textHint) : null,
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _isLoading ? null : _pickImageMock,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F5FF), // light blue
                      border: Border.all(color: const Color(0xFF1E96FC), width: 1.5), // blue border
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pilih File',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E96FC),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nama Pengguna label
            Text(
              'Nama Pengguna',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Nama Pengguna TextField
            TextFormField(
              controller: _nameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-.]+")),
                LengthLimitingTextInputFormatter(30),
              ],
            ),
            const SizedBox(height: 24),

            // Email label
            Text(
              'Email',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Email TextField
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(255),
              ],
            ),
            const SizedBox(height: 32),

            // Simpan Perubahan Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E96FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        'Simpan Perubahan',
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
    );
  }
}
