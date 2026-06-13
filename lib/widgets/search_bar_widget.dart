import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// TicketlySearchBar — Search bar dengan ikon cari
// Full-width, height 48px, border abu, radius 999
// Sesuai Figma: "Cari berdasarkan artis, lokasi, atau event..."
// ─────────────────────────────────────────────

class TicketlySearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const TicketlySearchBar({
    super.key,
    this.onTap,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.borderDefault, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(
                Icons.search,
                color: AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: onTap != null
                    // Read-only mode (hanya tap, navigasi ke search screen)
                    ? Text(
                        'Cari berdasarkan artis, lokasi, atau event...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    // Editable mode
                    : TextField(
                        controller: controller,
                        onChanged: onChanged,
                        style: AppTextStyles.bodyStyle,
                        decoration: InputDecoration(
                          hintText: 'Cari berdasarkan artis, lokasi, atau event...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
