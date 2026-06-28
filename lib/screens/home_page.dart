import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../data/home_dummy_data.dart';
import '../models/event_model.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';
import '../constants/api_constants.dart';
import '../widgets/hero_banner.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/horizontal_event_section.dart';
import '../widgets/faq_section.dart';
import '../widgets/home_sections.dart';
import '../widgets/bottom_nav_bar.dart';
import 'my_tickets_screen.dart';
import 'account_screen.dart';
import 'event_list_screen.dart';
import 'event_detail_screen.dart';

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

  List<HeroBannerItem> _heroBanners = [];
  List<EventModel> _concertEvents = [];
  List<EventModel> _festivalEvents = [];
  List<EventModel> _otherEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final landingData = await ApiService.fetchLandingPageData();

      if (mounted) {
        setState(() {
          _heroBanners = landingData.featured;
          _concertEvents = landingData.concerts;
          _festivalEvents = landingData.festivals;
          _otherEvents = landingData.events;
          _isLoading = false;
        });

        if (_heroBanners.isEmpty &&
            _concertEvents.isEmpty &&
            _festivalEvents.isEmpty &&
            _otherEvents.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal terhubung ke API backend (${ApiConstants.baseUrl}). Periksa koneksi server Anda.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.bluePrimary),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAllData,
                color: AppColors.bluePrimary,
                child: CustomScrollView(
                  slivers: [
                    // ── Custom AppBar ──
                    SliverToBoxAdapter(
                      child: _HomeAppBar(),
                    ),

                    // ── Hero Banner ──
                    if (_heroBanners.isNotEmpty)
                      SliverToBoxAdapter(
                        child: HeroBanner(items: _heroBanners),
                      ),

                    // ── Spacing ──
                    if (_heroBanners.isNotEmpty)
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
                    if (_concertEvents.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: HorizontalEventSection(
                          title: 'Konser Terbaru',
                          events: _concertEvents,
                          onLihatSemua: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => EventListScreen(
                                   title: 'Konser',
                                   subtitle: 'Jadwal Konser Musik',
                                   events: _concertEvents,
                                 ),
                               ),
                             );
                          },
                          onEventTap: (event) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(slug: event.slug),
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sectionVertical),
                      ),
                    ],

                    // ── Festival Seru ──
                    if (_festivalEvents.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: HorizontalEventSection(
                          title: 'Festival Seru',
                          events: _festivalEvents,
                          onLihatSemua: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => EventListScreen(
                                   title: 'Festival',
                                   subtitle: 'Festival Pilihan',
                                   events: _festivalEvents,
                                 ),
                               ),
                             );
                          },
                          onEventTap: (event) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(slug: event.slug),
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sectionVertical),
                      ),
                    ],

                    // ── Event Lainnya ──
                    if (_otherEvents.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: HorizontalEventSection(
                          title: 'Event Lainnya',
                          events: _otherEvents,
                          onLihatSemua: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => EventListScreen(
                                   title: 'Event Lainnya',
                                   subtitle: 'Jelajahi Semua Event',
                                   events: _otherEvents,
                                 ),
                               ),
                             );
                          },
                          onEventTap: (event) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(slug: event.slug),
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sectionVertical),
                      ),
                    ],

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
        bottomNavigationBar: TicketlyBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MyTicketsScreen(),
                  transitionDuration: Duration.zero,
                ),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AccountScreen(),
                  transitionDuration: Duration.zero,
                ),
              );
            } else {
              setState(() => _currentNavIndex = index);
            }
          },
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

class _HomeAppBar extends StatefulWidget {
  @override
  State<_HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<_HomeAppBar> {
  String _displayName = 'Tamu';
  String _avatarUrl = '';
  String _initial = 'T';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      final user = await AuthService.getUser();
      if (user != null && mounted) {
        setState(() {
          final username = user['username'] ?? 'User';
          _displayName = username;
          _avatarUrl = user['foto'] ?? '';
          _initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _displayName = 'Tamu';
          _avatarUrl = '';
          _initial = 'T';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hasImage = _avatarUrl.isNotEmpty && _avatarUrl.startsWith('http');

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
                  _displayName,
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
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
                child: hasImage
                    ? Image.network(
                        ApiService.normalizeImageUrl(_avatarUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            _initial,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluePrimary,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _initial,
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
