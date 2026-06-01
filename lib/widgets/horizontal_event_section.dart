import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';
import 'event_card.dart';
import 'section_header.dart';

// ─────────────────────────────────────────────
// HorizontalEventSection — Section lengkap dengan header + horizontal scroll
// Menggabungkan SectionHeader + ListView horizontal
// Hint scroll: card sedikit terpotong di kanan (padding akhir 32px)
// ─────────────────────────────────────────────

class HorizontalEventSection extends StatelessWidget {
  final String title;
  final List<EventModel> events;
  final VoidCallback? onLihatSemua;
  final ValueChanged<EventModel>? onEventTap;

  const HorizontalEventSection({
    super.key,
    required this.title,
    required this.events,
    this.onLihatSemua,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onLihatSemua: onLihatSemua),
        const SizedBox(height: 12),
        SizedBox(
          height: 270, // Tinggi card: image 100 + content ~170 (mencegah bottom overflow)
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppSpacing.screenHorizontal,
              right: 32, // Padding lebih besar di kanan = hint scroll
            ),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < events.length - 1 ? AppSpacing.cardGap : 0,
                ),
                child: EventCard(
                  event: event,
                  width: 160,
                  onTap: () => onEventTap?.call(event),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
