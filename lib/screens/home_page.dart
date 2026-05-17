import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../data/home_dummy_data.dart';
import '../widgets/hero_banner.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/horizontal_event_section.dart';
import '../widgets/faq_section.dart';
import '../widgets/home_sections.dart';
import '../widgets/bottom_nav_bar.dart';

// ─────────────────────────────────────────────
// HomePage — Ticketly Home Screen
// Sesuai desain Figma yang sudah diaudit
//
// Struktur:
//  [Custom AppBar] Greeting + Avatar
//  [Hero Banner] Carousel
//  [Tagline + Search]
//  [Konser Terbaru] Horizontal scroll
//  [Festival Seru] Horizontal scroll
//  [Event Lainnya] Horizontal scroll
//  [Promo Banner] Payday Sale
//  [Cara Beli Tiket] 4-step
//  [FAQ] Accordion
//  [Newsletter CTA]
//  [Trust Section]
//  [Bottom Nav]
// ─────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  // Data hero banner (placeholder — ganti dengan real data dari API)
  final List<HeroBannerItem> _heroBanners = const [
    HeroBannerItem(
      imageUrl: 'assets/images/banner_riize.png',
      eventName: 'RIIZING CUT — RIIZE LOUD IN JAKARTA',
      category: 'Konser',
      dateVenue: '5-6 Jan 2026 • ICE BSD Hall 5-6',
    ),
    HeroBannerItem(
      imageUrl: 'assets/images/banner_nct.png',
      eventName: 'NCT DREAM: THE DREAM SHOW 4 WORLD TOUR',
      category: 'Konser',
      dateVenue: '15 Jan 2026 • Jakarta International Stadium',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: Column(
          children: [
            // ── Content Area ──
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Custom AppBar ──
                  SliverToBoxAdapter(
                    child: _HomeAppBar(),
                  ),

                  // ── Hero Banner ──
                  SliverToBoxAdapter(
                    child: HeroBanner(items: _heroBanners),
                  ),

                  // ── Spacing ──
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Tagline + Search ──
                  SliverToBoxAdapter(
                    child: _TaglineAndSearch(),
                  ),

                  // ── Section Spacing ──
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Konser Terbaru ──
                  SliverToBoxAdapter(
                    child: HorizontalEventSection(
                      title: 'Konser Terbaru',
                      events: HomeDummyData.concertEvents,
                      onLihatSemua: () {
                        // TODO: Navigate to konser list screen
                      },
                      onEventTap: (event) {
                        // TODO: Navigate to event detail
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Festival Seru ──
                  SliverToBoxAdapter(
                    child: HorizontalEventSection(
                      title: 'Festival Seru',
                      events: HomeDummyData.festivalEvents,
                      onLihatSemua: () {
                        // TODO: Navigate to festival list screen
                      },
                      onEventTap: (event) {
                        // TODO: Navigate to event detail
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Event Lainnya ──
                  SliverToBoxAdapter(
                    child: HorizontalEventSection(
                      title: 'Event Lainnya',
                      events: HomeDummyData.otherEvents,
                      onLihatSemua: () {
                        // TODO: Navigate to other events screen
                      },
                      onEventTap: (event) {
                        // TODO: Navigate to event detail
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Promo Banner ──
                  SliverToBoxAdapter(
                    child: PromoBanner(
                      onTap: () {
                        // TODO: Navigate to promo page
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Cara Beli Tiket ──
                  const SliverToBoxAdapter(child: CaraBeli()),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── FAQ ──
                  SliverToBoxAdapter(
                    child: FaqSection(items: HomeDummyData.faqItems),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Newsletter CTA ──
                  const SliverToBoxAdapter(child: NewsletterCta()),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sectionVertical),
                  ),

                  // ── Trust Section ──
                  const SliverToBoxAdapter(child: TrustSection()),

                  // ── Bottom padding ──
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),

            // ── Bottom Navigation Bar ──
            TicketlyBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() => _currentNavIndex = index);
                // TODO: Handle navigation between tabs
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _HomeAppBar — Custom header Beranda
// Tidak pakai AppBar default Material
// Greeting teks + nama user + avatar kanan
// ─────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.screenBg,
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 12,
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Greeting + Nama ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hallo, Selamat Datang',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Hana', // TODO: Replace dengan nama user dari state/session
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar ──
          GestureDetector(
            onTap: () {
              // TODO: Navigate to profile
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bluePrimaryLight,
                border: Border.all(color: AppColors.bluePrimary, width: 2),
              ),
              child: ClipOval(
                child: Center(
                  child: Text(
                    'H', // Inisial user — ganti Image.network kalau ada foto
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _TaglineAndSearch — Teks promo + search bar
// "Temukan Pengalaman Seru Berikutnya!"
// Kata "Seru" di-highlight dengan warna accent
// ─────────────────────────────────────────────

class _TaglineAndSearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tagline
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              children: const [
                TextSpan(text: 'Temukan Pengalaman '),
                TextSpan(
                  text: 'Seru',
                  style: TextStyle(
                    color: AppColors.bluePrimary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.bluePrimary,
                    decorationThickness: 2,
                  ),
                ),
                TextSpan(text: ' Berikutnya!'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Search Bar
        TicketlySearchBar(
          onTap: () {
            // TODO: Navigate to search screen
          },
        ),
      ],
    );
  }
}
