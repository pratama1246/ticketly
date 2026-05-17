import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// SectionHeader — Header section dengan judul + "Lihat Semua"
// Dipakai di: Konser Terbaru, Festival Seru, Event Lainnya
// ─────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onLihatSemua;

  const SectionHeader({
    super.key,
    required this.title,
    this.onLihatSemua,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.sectionHeadingStyle),
          GestureDetector(
            onTap: onLihatSemua,
            child: Row(
              children: [
                Text(
                  'Lihat Semua',
                  style: AppTextStyles.labelStyle.copyWith(
                    color: AppColors.bluePrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.bluePrimary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
