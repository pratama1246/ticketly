import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// HeroBanner — Carousel banner event featured
// Full-width, aspect ratio ~16:7
// Dengan dot indicator di bawah
// ─────────────────────────────────────────────

class HeroBanner extends StatefulWidget {
  final List<HeroBannerItem> items;

  const HeroBanner({super.key, required this.items});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.items.isNotEmpty ? widget.items.length * 1000 : 0;
    _pageController = PageController(initialPage: initialPage);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.items.isEmpty) return;
      if (!mounted) return;
      final nextPage = (_pageController.page?.round() ?? 0) + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner Carousel ──
        AspectRatio(
          aspectRatio: 16 / 7,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (widget.items.isNotEmpty) {
                setState(() => _currentPage = index % widget.items.length);
              }
            },
            itemBuilder: (context, index) {
              if (widget.items.isEmpty) return const SizedBox.shrink();
              final item = widget.items[index % widget.items.length];
              return _HeroBannerSlide(item: item);
            },
          ),
        ),

        // ── Dot Indicator ──
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.bluePrimary
                    : AppColors.borderDefault,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBannerSlide extends StatelessWidget {
  final HeroBannerItem item;

  const _HeroBannerSlide({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Placeholder: gradient gelap — replace dengan Image.network
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Background image dari network
          if (item.imageUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white30, size: 48),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            )
          else
            // Placeholder content jika tidak ada image
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_outlined, color: Colors.white38, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    item.eventName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Gradient overlay dari bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),

          // Badge "KONSER" + tanggal event di bawah
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
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
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.eventName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.dateVenue,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBannerItem {
  final String imageUrl;
  final String eventName;
  final String category;
  final String dateVenue;

  const HeroBannerItem({
    required this.imageUrl,
    required this.eventName,
    required this.category,
    required this.dateVenue,
  });
}
