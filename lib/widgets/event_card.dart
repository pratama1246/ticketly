import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';

// ─────────────────────────────────────────────
// EventCard — Reusable card untuk semua section event
// Dipakai di: Konser Terbaru, Festival Seru, Event Lainnya
// Width: 160px (horizontal scroll)
// ─────────────────────────────────────────────

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final double? width;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 160,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.cardShadow,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Event Image ──
            _EventCardImage(
              imageUrl: event.imageUrl,
              isSoldOut: event.isSoldOut,
              badge: event.badge,
              eventDate: event.eventDate,
            ),

            // ── Event Info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama event — max 2 baris
                    Text(
                      event.title,
                      style: AppTextStyles.cardTitleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Lokasi
                    _EventMetaRow(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                    const SizedBox(height: 4),

                    // Waktu
                    _EventMetaRow(
                      icon: Icons.access_time_outlined,
                      text: event.time,
                    ),

                    const Spacer(), // Push button to bottom

                    // Tombol Selengkapnya — outlined small
                    _SelengkapnyaButton(onTap: onTap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widget: Image area dengan overlay sold out ──
class _EventCardImage extends StatelessWidget {
  final String imageUrl;
  final bool isSoldOut;
  final String? badge;
  final DateTime? eventDate;

  const _EventCardImage({
    required this.imageUrl,
    required this.isSoldOut,
    this.badge,
    this.eventDate,
  });

  String _getMonthAbbreviation(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
    ];
    if (date.month >= 1 && date.month <= 12) {
      return months[date.month - 1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scaling image container via AspectRatio (16:9 video ratio to look modern and prevent overlap issues)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFD1D5DB),
            child: imageUrl.isNotEmpty
                ? (imageUrl.startsWith('assets/')
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 32),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ))
                : const Center(
                    child: Icon(Icons.image_outlined, color: Color(0xFF9CA3AF), size: 32),
                  ),
          ),
        ),

        // Sold-out overlay
        if (isSoldOut)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9CA3AF),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    'Habis',
                    style: AppTextStyles.captionStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Optional badge (e.g. HOT, NEW)
        if (badge != null && !isSoldOut)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                badge!,
                style: AppTextStyles.captionStyle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),

        // Calendar Date Badge
        if (eventDate != null && !isSoldOut)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getMonthAbbreviation(eventDate!),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eventDate!.day.toString(),
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Sub-widget: Row ikon + teks (lokasi/waktu) ──
class _EventMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EventMetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.captionStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Sub-widget: Tombol "Selengkapnya" outlined small ──
class _SelengkapnyaButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SelengkapnyaButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bluePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Selengkapnya',
          style: AppTextStyles.captionStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
