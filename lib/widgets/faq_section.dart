import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/home_dummy_data.dart';

// ─────────────────────────────────────────────
// FaqSection — FAQ accordion dengan expand/collapse
// Background card putih, radius 12, shadow ringan
// Ikon: chevron (bukan plus/minus)
// Animasi expand: 250ms
// ─────────────────────────────────────────────

class FaqSection extends StatelessWidget {
  final List<FaqModel> items;

  const FaqSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pertanyaan Populer', style: AppTextStyles.sectionHeadingStyle),
          const SizedBox(height: 4),
          Text(
            'Hal yang sering ditanyakan oleh pengguna Ticketly',
            style: AppTextStyles.captionStyle,
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _FaqItem(item: item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final FaqModel item;

  const _FaqItem({required this.item});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        boxShadow: AppShadows.cardShadow,
      ),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Question row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: AppTextStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ── Answer (expand/collapse) ──
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      widget.item.answer,
                      style: AppTextStyles.bodyStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
