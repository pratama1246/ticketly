import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// PromoBanner — Banner promo Payday Sale
// Background: gradient biru/ungu, CTA button kuning
// ─────────────────────────────────────────────

class PromoBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const PromoBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF072AC8), Color(0xFF7C3AED)], // Biru ke Ungu sesuai DESIGN.md
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      'PROMO TERBATAS',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payday Sale! Diskon 20%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dapatkan diskon untuk semua tiket konser internasional. Berlaku sampai akhir bulan.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'Cek Promo Sekarang',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Ilustrasi placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_offer_outlined, color: Colors.white30, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CaraBeli — Section 4-step guide beli tiket
// Numbering dengan lingkaran biru/kuning
// ─────────────────────────────────────────────

class CaraBeli extends StatelessWidget {
  const CaraBeli({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData(number: '1', title: 'Pilih Event', desc: 'Cari event favoritmu di halaman utama.'),
      _StepData(number: '2', title: 'Pilih Tiket', desc: 'Tentukan kategori dan jumlah tiket yang diinginkan.'),
      _StepData(number: '3', title: 'Bayar', desc: 'Selesaikan pembayaran melalui metode yang tersedia.'),
      _StepData(number: '4', title: 'Selesai', desc: 'E-Tiket dikirim ke email. Sampai di venue, scan & masuk!'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cara Beli Tiket', style: AppTextStyles.sectionHeadingStyle),
          const SizedBox(height: 4),
          Text(
            'Dapatkan tiketmu hanya dalam hitungan menit.',
            style: AppTextStyles.captionStyle,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: steps.map((step) => _StepCard(data: step)).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String number;
  final String title;
  final String desc;

  const _StepData({
    required this.number,
    required this.title,
    required this.desc,
  });
}

class _StepCard extends StatelessWidget {
  final _StepData data;

  const _StepCard({required this.data});

  @override
  Widget build(BuildContext context) {
    Color circleBgColor;
    Color circleTextColor;

    switch (data.number) {
      case '1':
        circleBgColor = const Color(0xFFE6EAFA);
        circleTextColor = const Color(0xFF072AC8);
        break;
      case '2':
        circleBgColor = const Color(0xFFE9F5FF);
        circleTextColor = const Color(0xFF1E96FC);
        break;
      case '3':
        circleBgColor = const Color(0xFFFFFBE6);
        circleTextColor = const Color(0xFFD97706);
        break;
      case '4':
        circleBgColor = const Color(0xFFDCFCE7);
        circleTextColor = const Color(0xFF22C55E);
        break;
      default:
        circleBgColor = AppColors.accentYellow;
        circleTextColor = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.number,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: circleTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: AppTextStyles.cardTitleStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              data.desc,
              style: AppTextStyles.captionStyle.copyWith(height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NewsletterCta — Input email + tombol berlangganan
// Background biru gelap (#072AC8)
// ─────────────────────────────────────────────

class NewsletterCta extends StatelessWidget {
  const NewsletterCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bluePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jangan Ketinggalan Info Konser!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dapatkan update event terbaru, promo tiket early-bird, dan pengingat eksklusif langsung di inbox emailmu.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: TextField(
                      style: AppTextStyles.bodyStyle,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat emailmu...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      'Berlangganan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TrustSection — 3 keunggulan Ticketly
// 3 kolom icon + teks
// ─────────────────────────────────────────────

class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        children: [
          Text(
            'Kenapa Beli di Ticketly',
            style: AppTextStyles.sectionHeadingStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Platform tiket event terpercaya dengan jutaan pengguna di seluruh Indonesia.',
            style: AppTextStyles.captionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TrustItem(
                icon: Icons.verified_outlined,
                iconColor: AppColors.bluePrimary,
                bgColor: const Color(0xFFE6EAFA),
                borderColor: AppColors.bluePrimary.withOpacity(0.4),
                label: 'Transaksi\n100% Aman',
              ),
              _TrustItem(
                icon: Icons.confirmation_number_outlined,
                iconColor: const Color(0xFFEC4899),
                bgColor: const Color(0xFFFCE7F3),
                borderColor: const Color(0xFFEC4899).withOpacity(0.4),
                label: 'E-Tiket\nInstant',
              ),
              _TrustItem(
                icon: Icons.headset_mic_outlined,
                iconColor: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFFE4E6),
                borderColor: const Color(0xFFEF4444).withOpacity(0.4),
                label: 'Bantuan\n24/7',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String label;

  const _TrustItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.captionStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
