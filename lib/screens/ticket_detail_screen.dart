import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_detail_model.dart';
import '../theme/app_theme.dart';

class TicketDetailScreen extends StatelessWidget {
  final OrderDetailModel order;
  final OrderItemModel ticket;
  final int ticketIndex;
  final int totalTickets;

  const TicketDetailScreen({
    super.key,
    required this.order,
    required this.ticket,
    required this.ticketIndex,
    required this.totalTickets,
  });

  @override
  Widget build(BuildContext context) {
    // Generate QR Code URL using QRServer API
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${ticket.ticketCode}';

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        title: Text(
          'My Ticket',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Outer card wrapping the ticket layout
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.cardShadow,
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Blue Header Area
                  Container(
                    width: double.infinity,
                    color: AppColors.bluePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        // Ticketly Logo Text Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tick',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFFC600), // accentYellow
                              ),
                            ),
                            Text(
                              'etly',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'E-TIKET RESMI',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ORDER ID: ${order.trxId}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ticket Body Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        Center(
                          child: Text(
                            ticket.eventName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Info Grid Box
                        _buildInfoRow('PEMBELI', _getBuyerName()),
                        const Divider(height: 18, color: AppColors.borderDefault),
                        _buildInfoRow('TANGGAL', ticket.eventDate),
                        const Divider(height: 18, color: AppColors.borderDefault),
                        _buildInfoRow('WAKTU', ticket.eventTime),
                        const Divider(height: 18, color: AppColors.borderDefault),
                        _buildInfoRow('LOKASI', ticket.eventName.contains('RIIZE') ? 'ICE BSD Hall 5-6' : 'Jakarta International Stadium'),
                        const Divider(height: 18, color: AppColors.borderDefault),
                        _buildInfoRow('KATEGORI', ticket.ticketName),
                        const Divider(height: 18, color: AppColors.borderDefault),
                        _buildInfoRow('NOMOR KURSI', ticket.seatLabel, valueColor: AppColors.bluePrimary),

                        const SizedBox(height: 16),
                        // Dotted Divider Line
                        Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: 1.5,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // QR Code Scanner Box
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'scan di pintu masuk',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.borderDefault, width: 1.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.network(
                                  qrUrl,
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: AppColors.bluePrimary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                ticket.ticketCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grey Footer
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '© 2025 Ticketly System. Tiket $ticketIndex dari $totalTickets',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Extracts buyer name from first_name / email
  String _getBuyerName() {
    return 'Hanah'; // fallback from mockup
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Text(':   '),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
