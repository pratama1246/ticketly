import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/order_detail_model.dart';
import '../service/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'account_screen.dart';
import 'home_page.dart';
import 'login_screen.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OrderDetailModel> _completedOrders = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadTickets();
  }

  Future<void> _checkAuthAndLoadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi habis. Silakan login kembali.';
      });
      return;
    }

    try {
      // 1. Fetch all orders
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/orders'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final List ordersRaw = decoded['data'];
          
          // Filter completed orders
          final completedOrdersList = ordersRaw
              .where((o) => o['status'] == 'completed')
              .toList();

          final List<OrderDetailModel> detailedOrders = [];

          // 2. Fetch details for each completed order (to get items/tickets)
          for (final order in completedOrdersList) {
            final orderId = order['id'];
            final detailResponse = await http.get(
              Uri.parse('${ApiConstants.baseUrl}/api/orders/$orderId'),
              headers: {'Authorization': 'Bearer $token'},
            ).timeout(const Duration(seconds: 5));

            if (detailResponse.statusCode == 200) {
              final detailDecoded = json.decode(detailResponse.body);
              if (detailDecoded['status'] == 'success' && detailDecoded['data'] != null) {
                detailedOrders.add(OrderDetailModel.fromJson(detailDecoded['data']));
              }
            }
          }

          if (mounted) {
            setState(() {
              _completedOrders = detailedOrders;
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat tiket Anda.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan jaringan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Flatten list of orders to tickets list for direct card display
    final List<_TicketListItem> ticketsToRender = [];
    for (final order in _completedOrders) {
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        ticketsToRender.add(_TicketListItem(
          order: order,
          ticket: item,
          index: i + 1,
          total: order.items.length,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        title: const Text('Tiket Saya'),
        centerTitle: false,
        backgroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.bluePrimary),
              onPressed: _checkAuthAndLoadTickets,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary))
          : (_errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkAuthAndLoadTickets,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : (ticketsToRender.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tiket',
                            style: AppTextStyles.pageTitleStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tiket yang kamu beli akan muncul di sini',
                            style: AppTextStyles.bodyStyle,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: ticketsToRender.length,
                      itemBuilder: (context, index) {
                        final item = ticketsToRender[index];
                        return _buildTicketCard(context, item);
                      },
                    ))),
      bottomNavigationBar: TicketlyBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomePage(),
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
          }
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, _TicketListItem item) {
    // Determine dynamic poster fallback / mapping based on event title
    final String posterUrl = item.ticket.eventName.contains('RIIZE')
        ? '${ApiConstants.baseUrl}/uploads/banners/riizing-loud.png'
        : '${ApiConstants.baseUrl}/uploads/banners/tds-4.jpg';

    // Normalize address mapping
    final String venue = item.ticket.eventName.contains('RIIZE')
        ? 'ICE BSD Hall 5-6'
        : 'Jakarta International Stadium';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault, width: 1.2),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Poster thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    posterUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.bluePrimaryLight,
                      child: const Icon(Icons.music_note, color: AppColors.bluePrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ticket.eventName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            item.ticket.eventDate,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              venue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.borderDefault),
          
          // Action Button Area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    '${item.ticket.ticketName} • ${item.ticket.seatLabel}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketDetailScreen(
                            order: item.order,
                            ticket: item.ticket,
                            ticketIndex: item.index,
                            totalTickets: item.total,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Lihat Tiket',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
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

// Private helper to wrap Ticket item alongside its Order container details
class _TicketListItem {
  final OrderDetailModel order;
  final OrderItemModel ticket;
  final int index;
  final int total;

  const _TicketListItem({
    required this.order,
    required this.ticket,
    required this.index,
    required this.total,
  });
}
