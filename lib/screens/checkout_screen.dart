import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/event_detail_model.dart';
import '../service/auth_service.dart';
import '../theme/app_theme.dart';
import 'my_tickets_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final EventDetailModel event;
  final Map<int, int> selectedQuantities;
  final int subtotal;
  final int totalQty;

  const CheckoutScreen({
    super.key,
    required this.event,
    required this.selectedQuantities,
    required this.subtotal,
    required this.totalQty,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 1; // Step 1: S&K, 2: Data Diri, 3: Metode Pembayaran, 4: Konfirmasi, 5: Detail Tagihan
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Step 1: Syarat & Ketentuan
  bool _isTnCAccepted = false;

  // Step 2: Metode Pembayaran
  List<Map<String, dynamic>> _paymentMethods = [];
  String? _selectedMethodCode;
  String? _selectedMethodName;
  String? _selectedMethodType;
  String? _selectedMethodLogo;

  // Step 3: Data Diri Form & Consent Checkboxes
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _dobController = TextEditingController();

  String _waConsent = 'iya'; // 'iya' or 'tidak'
  bool _agreeTnC = false;
  bool _agreeProcessing = false;

  // Dynamic pricing calculated from backend /api/checkout/calculate
  int _apiSubTotal = 0;
  int _apiTaxAmount = 0;
  int _apiPlatformFee = 0;
  int _apiAdminFee = 0;
  int _apiGrandTotal = 0;
  bool _isLoadingCalculation = false;

  // Step 4: Order Creation Result
  int? _createdOrderId;
  String? _createdTrxId;
  int? _createdGrandTotal;
  DateTime? _expiresAt;

  // Dual Timers
  Timer? _checkoutTimer;
  int _checkoutSecondsRemaining = 300; // 5:00 minutes checkout session (Steps 1-4)

  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15:00 minutes payment session (Step 5)

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPaymentMethods();
    _calculatePricing();
  }

  @override
  void dispose() {
    _checkoutTimer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _startCheckoutTimer() {
    _checkoutTimer?.cancel();
    _checkoutSecondsRemaining = 300;
    _checkoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_checkoutSecondsRemaining > 0) {
            _checkoutSecondsRemaining--;
          } else {
            _checkoutTimer?.cancel();
            _handleCheckoutSessionExpired();
          }
        });
      }
    });
  }

  void _startPaymentTimer(DateTime expiresAt) {
    _checkoutTimer?.cancel();
    _countdownTimer?.cancel();

    final now = DateTime.now();
    _secondsRemaining = expiresAt.difference(now).inSeconds;
    if (_secondsRemaining < 0) _secondsRemaining = 0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _countdownTimer?.cancel();
            _handlePaymentSessionExpired();
          }
        });
      }
    });
  }

  void _handleCheckoutSessionExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sesi Berakhir',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'Waktu checkout Anda telah habis (5 menit). Silakan ulangi pemesanan Anda.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to event detail
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary),
            child: const Text('Kembali'),
          )
        ],
      ),
    );
  }

  void _handlePaymentSessionExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sesi Pembayaran Berakhir',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'Waktu pembayaran tagihan Anda telah habis. Pesanan dibatalkan secara otomatis.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to event detail
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary),
            child: const Text('Kembali'),
          )
        ],
      ),
    );
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _firstNameController.text = '';
        _lastNameController.text = '';
        _emailController.text = user['email'] ?? '';
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/api/checkout/payment-methods'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final Map<String, dynamic> groupedData = decoded['data'];
          final List<Map<String, dynamic>> flattened = [];
          
          groupedData.forEach((type, list) {
            if (list is List) {
              for (final m in list) {
                flattened.add(Map<String, dynamic>.from(m));
              }
            }
          });

          if (mounted) {
            setState(() {
              _paymentMethods = flattened;
              if (_paymentMethods.isNotEmpty) {
                _selectPaymentMethod(_paymentMethods.first);
              }
            });
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback payment methods if offline
    if (mounted) {
      setState(() {
        _paymentMethods = [
          {'name': 'BCA Virtual Account', 'code': 'bca', 'type': 'virtual_account'},
          {'name': 'BNI Virtual Account', 'code': 'bni', 'type': 'virtual_account'},
          {'name': 'BRI Virtual Account', 'code': 'bri', 'type': 'virtual_account'},
          {'name': 'Mandiri Bill', 'code': 'mandiri_bill', 'type': 'virtual_account'},
          {'name': 'GoPay', 'code': 'gopay', 'type': 'ewallet'},
          {'name': 'OVO', 'code': 'ovo', 'type': 'ewallet'},
          {'name': 'DANA', 'code': 'dana', 'type': 'ewallet'},
          {'name': 'ShopeePay', 'code': 'shopeepay', 'type': 'ewallet'},
          {'name': 'Allo Bank', 'code': 'allobank', 'type': 'other'},
          {'name': 'Akulaku PayLater', 'code': 'akulaku', 'type': 'other'},
        ];
        _selectPaymentMethod(_paymentMethods.first);
      });
    }
  }

  void _selectPaymentMethod(Map<String, dynamic> method) {
    setState(() {
      _selectedMethodCode = method['code'];
      _selectedMethodName = method['name'];
      _selectedMethodType = method['type'];
      _selectedMethodLogo = method['logo_image'];
    });
  }

  Future<void> _calculatePricing() async {
    setState(() => _isLoadingCalculation = true);

    // Prepare tickets array payload
    final List<Map<String, dynamic>> ticketsPayload = [];
    widget.selectedQuantities.forEach((ticketTypeId, qty) {
      if (qty > 0) {
        ticketsPayload.add({
          'ticket_type_id': ticketTypeId,
          'quantity': qty,
        });
      }
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/checkout/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'tickets': ticketsPayload}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final data = decoded['data'];
          if (mounted) {
            setState(() {
              _apiSubTotal = _parseInt(data['sub_total']);
              _apiTaxAmount = _parseInt(data['tax_amount']);
              _apiPlatformFee = _parseInt(data['platform_fee']);
              _apiAdminFee = _parseInt(data['admin_fee']);
              _apiGrandTotal = _parseInt(data['grand_total']);
              _isLoadingCalculation = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // Local calculation fallback (11% tax, 10000 platform fee per ticket, 2500 admin fee)
    if (mounted) {
      final sub = widget.subtotal;
      final tax = (sub * 0.11).toInt();
      final platform = widget.totalQty * 10000;
      const admin = 2500;
      setState(() {
        _apiSubTotal = sub;
        _apiTaxAmount = tax;
        _apiPlatformFee = platform;
        _apiAdminFee = admin;
        _apiGrandTotal = sub + tax + platform + admin;
        _isLoadingCalculation = false;
      });
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  String _formatTimerText(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Calls API to create a pending order on the server
  Future<void> _startOrderOnServer() async {
    setState(() => _isLoading = true);

    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      _showToast('Sesi Anda habis. Silakan login kembali.');
      return;
    }

    final List<Map<String, dynamic>> ticketsPayload = [];
    widget.selectedQuantities.forEach((ticketTypeId, qty) {
      if (qty > 0) {
        ticketsPayload.add({
          'ticket_type_id': ticketTypeId,
          'quantity': qty,
        });
      }
    });

    final body = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'identity_number': _nikController.text.trim(),
      'payment_method': _selectedMethodCode,
      'tickets': ticketsPayload,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/checkout/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final decoded = json.decode(response.body);

      if (response.statusCode == 201 && decoded['status'] == 'success') {
        final data = decoded['data'];
        final String expiresAtStr = data['expires_at'];
        final parsedExpiresAt = DateTime.tryParse(expiresAtStr) ?? DateTime.now().add(const Duration(minutes: 15));

        setState(() {
          _createdOrderId = _parseInt(data['order_id']);
          _createdTrxId = data['trx_id'];
          _createdGrandTotal = _parseInt(data['grand_total']);
          _expiresAt = parsedExpiresAt;
          _currentStep = 5;
          _isLoading = false;
        });
        _scrollToTop();
        _startPaymentTimer(parsedExpiresAt);
      } else {
        setState(() => _isLoading = false);
        _showToast(decoded['message'] ?? 'Gagal membuat pesanan.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Gagal menghubungi server: $e');
    }
  }

  // Opens the "Sudah Melakukan Pembayaran?" Dialog
  void _showConfirmPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // $ circular icon matching design
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6EAFA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_money, size: 36, color: AppColors.bluePrimary),
                ),
                const SizedBox(height: 20),

                Text(
                  'Sudah Melakukan Pembayaran?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Pastikan nominal transfer sesuai hingga digit terakhir. Pesan akan diproses otomatis.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Coba Lagi',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close confirm dialog
                            _finalizePaymentOnServer();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bluePrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ya, Sudah Bayar',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Finalizes payment call on server -> status set to completed, email is sent
  Future<void> _finalizePaymentOnServer() async {
    setState(() => _isLoading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      _showToast('Sesi habis. Silakan login kembali.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/checkout/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'order_id': _createdOrderId}),
      ).timeout(const Duration(seconds: 15));

      final decoded = json.decode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        final email = decoded['data']['email'] ?? _emailController.text;
        final trxId = decoded['data']['trx_id'] ?? _createdTrxId;
        _showSuccessDialog(email, trxId);
      } else {
        _showToast(decoded['message'] ?? 'Konfirmasi gagal. Silakan coba lagi.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Gagal konfirmasi pembayaran: $e');
    }
  }

  // Opens the green "Pembayaran Berhasil" Dialog
  void _showSuccessDialog(String email, String trxId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green check icon matching design
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 36, color: Color(0xFF16A34A)),
                ),
                const SizedBox(height: 20),

                Text(
                  'Pembayaran Berhasil',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Terima kasih E-Tiket telah dikirim ke email atau dapat dilihat di halaman Tiket Saya.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Grey details box matching mockup
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $trxId',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Green Button "Lihat Tiket Saya"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close checkout wizard screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MyTicketsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Lihat Tiket Saya',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Cancel order call on server -> status set to cancelled
  Future<void> _cancelOrderOnServer() async {
    setState(() => _isLoading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/checkout/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'order_id': _createdOrderId}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context); // Return to Event detail page
      _showToast('Pesanan berhasil dibatalkan.');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.textPrimary),
    );
  }

  // Copy VA number helper
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('Nomor Virtual Account berhasil disalin.');
  }

  // Generates dummy VA based on selected payment code and order ID
  String _getVirtualAccountNumber() {
    final idStr = (_createdOrderId ?? 1).toString();
    if (_selectedMethodCode == 'bca') {
      return '88004${idStr.padLeft(9, '0')}';
    } else if (_selectedMethodCode == 'bri') {
      return '88004252${idStr.padLeft(6, '0')}';
    } else if (_selectedMethodCode == 'bni') {
      return '827${idStr.padLeft(11, '0')}';
    } else if (_selectedMethodCode == 'mandiri_bill') {
      return '89608${idStr.padLeft(9, '0')}';
    }
    return '88004252937788'; // fallback from mockup screenshot
  }

  // Generates dummy payment instructions text based on selected payment method code
  List<String> _getPaymentInstructions() {
    if (_selectedMethodType == 'ewallet') {
      return [
        'Buka aplikasi e-wallet Anda.',
        'Pilih menu **bayar / scan QRIS**.',
        'Masukkan nomor transaksi atau pindai QR code.',
        'Periksa detail tagihan Anda.',
        'Masukkan PIN Anda untuk menyelesaikan pembayaran.'
      ];
    }
    return [
      'Buka aplikasi Mobile Banking atau ATM Anda.',
      'Pilih menu **Transfer Virtual Account**.',
      'Masukkan Nomor VA: **${_getVirtualAccountNumber()}**.',
      'Periksa detail nama dan total tagihan.',
      'Masukkan PIN Anda dan simpan bukti transaksi.'
    ];
  }


  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(2, Icons.person_outline, 'Data Diri', 'Info Pemesan'),
          _buildStepDivider(2),
          _buildStepCircle(3, Icons.credit_card, 'Metode', 'Metode Bayar'),
          _buildStepDivider(3),
          _buildStepCircle(4, Icons.assignment_outlined, 'Konfirmasi', 'Cek Pesanan'),
          _buildStepDivider(4),
          _buildStepCircle(5, Icons.account_balance_wallet_outlined, 'Bayar', 'Selesaikan'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNum, IconData iconData, String title, String subtitle) {
    final isCompleted = _currentStep > stepNum;
    final isActive = _currentStep == stepNum;

    Widget circle = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFDCFCE7)
            : (isActive ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6)),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCompleted ? Icons.check : iconData,
        size: 18,
        color: isCompleted
            ? const Color(0xFF16A34A)
            : (isActive ? AppColors.bluePrimary : const Color(0xFF9CA3AF)),
      ),
    );

    if (isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return circle;
    }
  }

  Widget _buildStepDivider(int stepAfter) {
    final isCompleted = _currentStep > stepAfter;
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 1:
        return 'Syarat & Ketentuan';
      case 2:
        return 'Data Diri';
      case 3:
        return 'Metode Pembayaran';
      case 4:
        return 'Konfirmasi Pesanan';
      case 5:
        return 'Konfirmasi Pesanan';
      default:
        return 'Checkout';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 5) {
              setState(() {
                _currentStep--;
                if (_currentStep == 1) {
                  _checkoutTimer?.cancel();
                }
              });
              _scrollToTop();
            } else if (_currentStep == 5) {
              // Confirm canceling order if they try to leave VA step
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Batalkan Pesanan?'),
                  content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tidak'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelOrderOnServer();
                      },
                      child: const Text('Ya, Batalkan'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_currentStep > 1) _buildStepIndicator(),
              Expanded(
                child: _isLoadingCalculation
                    ? const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary))
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_currentStep >= 2 && _currentStep <= 4) const SizedBox(height: 48),
                            _buildStepContent(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          if (_currentStep >= 2 && _currentStep <= 4)
            Positioned(
              top: 72.0, // Floating below the stepper indicator
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, color: Color(0xFF4F46E5), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Sisa waktu  ',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                      Text(
                        _formatTimerText(_checkoutSecondsRemaining),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.bluePrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildTnCStep();
      case 2:
        return _buildDataDiriStep();
      case 3:
        return _buildPaymentMethodStep();
      case 4:
        return _buildConfirmOrderStep();
      case 5:
        return _buildBillDetailStep();
      default:
        return Container();
    }
  }

  // ─────────────────────────────────────────────
  // STEP 1: Syarat & Ketentuan
  // ─────────────────────────────────────────────
  Widget _buildTnCStep() {
    final List<String> absoluteTerms = [
      'Penonton wajib memiliki tiket resmi dan menunjukkan e-ticket yang dimiliki.',
      'Tiket yang sudah dibeli tidak dapat dikembalikan atau ditukar.',
      'Penyelenggara berhak menolak atau mengeluarkan penonton yang mengganggu ketertiban.',
      'Dilarang membawa senjata, alkohol, parfum, narkoba, makanan/minuman dari luar, dan kamera profesional.',
      'Penonton wajib menjaga ketertiban, kebersihan, serta mengikuti arahan petugas.',
      'Penyelenggara berhak mendokumentasikan acara dan menggunakan hasilnya untuk publikasi.',
      'Jadwal dapat berubah tanpa pemberitahuan.',
      'Penyelenggara tidak bertanggung jawab atas kehilangan atau kerusakan barang pribadi.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...absoluteTerms.map((term) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      term,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _isTnCAccepted,
              activeColor: AppColors.bluePrimary,
              onChanged: (val) {
                setState(() {
                  _isTnCAccepted = val ?? false;
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isTnCAccepted = !_isTnCAccepted;
                  });
                },
                child: Text(
                  'Klik Untuk Melanjutkan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isTnCAccepted
                ? () {
                    setState(() {
                      _currentStep = 2;
                      _startCheckoutTimer();
                    });
                    _scrollToTop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTnCAccepted ? AppColors.bluePrimary : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Lanjut',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataDiriStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Nama Depan', isRequired: true),
          TextFormField(
            controller: _firstNameController,
            validator: (val) => val == null || val.trim().isEmpty ? 'Nama depan wajib diisi' : null,
            decoration: _buildInputDecoration('Masukkan nama depan'),
            style: GoogleFonts.poppins(fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-.]+")),
              LengthLimitingTextInputFormatter(100),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Nama Belakang'),
          TextFormField(
            controller: _lastNameController,
            decoration: _buildInputDecoration('Masukkan nama belakang'),
            style: GoogleFonts.poppins(fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-.]+")),
              LengthLimitingTextInputFormatter(100),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Email', isRequired: true),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(val.trim())) {
                return 'Masukkan email yang valid';
              }
              return null;
            },
            decoration: _buildInputDecoration('nama@domain.com'),
            style: GoogleFonts.poppins(fontSize: 14),
            inputFormatters: [
              LengthLimitingTextInputFormatter(255),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Nomor Telepon', isRequired: true),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (val) => val == null || val.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
            decoration: _buildInputDecoration('08xxxxxxxxxx'),
            style: GoogleFonts.poppins(fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Nomor Identitas (KTP/SIM/NIK/Paspor,dll)', isRequired: true),
          TextFormField(
            controller: _nikController,
            keyboardType: TextInputType.text,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Nomor identitas wajib diisi' : null,
            decoration: _buildInputDecoration('Masukkan nomor identitas'),
            style: GoogleFonts.poppins(fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Tanggal Lahir'),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDate(context),
            decoration: _buildInputDecoration('DD/MM/YYYY', prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A))),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 20),

          Text(
            'Saya setuju untuk menerima notifikasi terkait pemesanan tiket berikut melalui nomor WhatsApp saya.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Radio<String>(
                value: 'iya',
                groupValue: _waConsent,
                activeColor: AppColors.bluePrimary,
                onChanged: (val) {
                  setState(() {
                    _waConsent = val!;
                  });
                },
              ),
              Text(
                'Iya',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(width: 30),
              Radio<String>(
                value: 'tidak',
                groupValue: _waConsent,
                activeColor: AppColors.bluePrimary,
                onChanged: (val) {
                  setState(() {
                    _waConsent = val!;
                  });
                },
              ),
              Text(
                'Tidak',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Checkbox 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreeTnC,
                activeColor: AppColors.bluePrimary,
                onChanged: (val) {
                  setState(() {
                    _agreeTnC = val ?? false;
                  });
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, height: 1.4),
                      children: const [
                        TextSpan(text: 'Dengan mengklik "Lanjut", kamu menyetujui '),
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' dan '),
                        TextSpan(
                          text: 'Kebijakan Privasi',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' Ticketly.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Checkbox 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreeProcessing,
                activeColor: AppColors.bluePrimary,
                onChanged: (val) {
                  setState(() {
                    _agreeProcessing = val ?? false;
                  });
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, height: 1.4),
                      children: const [
                        TextSpan(text: 'Dengan mengklik "Lanjut", kamu menyetujui '),
                        TextSpan(
                          text: 'Kebijakan Pemrosesan Data Pribadi',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' Ticketly.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_agreeTnC && _agreeProcessing)
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _currentStep = 3;
                        });
                        _scrollToTop();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_agreeTnC && _agreeProcessing) ? AppColors.bluePrimary : Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Lanjut',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: (_agreeTnC && _agreeProcessing) ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Batalkan Checkout?'),
                    content: const Text('Apakah Anda yakin ingin membatalkan checkout ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tidak'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Ya, Batal'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.bluePrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Widget _buildFieldLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  )
                ]
              : [],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.bluePrimary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  Widget _buildPaymentMethodStep() {
    final ewallets = _paymentMethods.where((m) => m['type'] == 'ewallet').toList();
    final vas = _paymentMethods.where((m) => m['type'] == 'virtual_account').toList();
    final others = _paymentMethods.where((m) => m['type'] == 'other').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E-Wallet group
        _buildPaymentGroupHeader('E-Wallet'),
        ...ewallets.map((m) => _buildPaymentItem(m)),
        const SizedBox(height: 16),

        // VA group
        _buildPaymentGroupHeader('Virtual Account'),
        ...vas.map((m) => _buildPaymentItem(m)),
        const SizedBox(height: 16),

        // Paylater group
        _buildPaymentGroupHeader('PayLater & Digital Bank'),
        ...others.map((m) => _buildPaymentItem(m)),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedMethodCode != null
                ? () {
                    setState(() {
                      _currentStep = 4;
                    });
                    _scrollToTop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Lanjut',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
              _scrollToTop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Kembali',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> method) {
    final code = method['code'];
    final name = method['name'];
    final logo = method['logo_image'];
    final isSelected = _selectedMethodCode == code;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE9F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.bluePrimary : AppColors.borderDefault,
          width: isSelected ? 1.5 : 1.2,
        ),
      ),
      child: ListTile(
        onTap: () => _selectPaymentMethod(method),
        leading: Container(
          width: 44,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[200]!, width: 0.8),
          ),
          child: logo != null && logo.isNotEmpty && !logo.endsWith('.svg')
              ? Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPaymentLogoFallback(code, name),
                )
              : _buildPaymentLogoFallback(code, name),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.bluePrimary : Colors.grey[400]!,
              width: isSelected ? 6 : 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // Fallback if SVG or network failure
  Widget _buildPaymentLogoFallback(String code, String name) {
    String initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
    if (initials.length > 3) initials = initials.substring(0, 3);
    if (code == 'bca') initials = 'BCA';
    if (code == 'bri') initials = 'BRI';
    if (code == 'bni') initials = 'BNI';
    if (code == 'mandiri_bill') initials = 'MDR';

    Color brandColor = AppColors.bluePrimary;
    if (code == 'bca') brandColor = const Color(0xFF005CAA);
    if (code == 'bri') brandColor = const Color(0xFF003882);
    if (code == 'bni') brandColor = const Color(0xFFE55300);
    if (code == 'gopay') brandColor = const Color(0xFF00AED6);
    if (code == 'ovo') brandColor = const Color(0xFF4C2A86);
    if (code == 'dana') brandColor = const Color(0xFF108EE9);
    if (code == 'shopeepay') brandColor = const Color(0xFFEE4D2D);

    return Container(
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: brandColor,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 3: Konfirmasi Pesanan (Data Diri + Summary)
  // ─────────────────────────────────────────────
  Widget _buildConfirmOrderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event summary + Tiket yang Dipesan + Data Diri in a single card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Poster
              if (widget.event.posterImage != null && widget.event.posterImage!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    widget.event.posterImage!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name
                    Text(
                      widget.event.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Date, time, venue
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          widget.event.date,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          widget.event.time.isNotEmpty ? widget.event.time : '19.00 - 21.00 WIB',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.venue,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.borderDefault),
                    
                    // Tiket yang Dipesan
                    Text(
                      'Tiket yang Dipesan',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    ...widget.selectedQuantities.entries.map((entry) {
                      if (entry.value <= 0) return Container();
                      final ticket = widget.event.tickets.firstWhere((t) => t.id == entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${entry.value}x ${ticket.name}',
                              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            Text(
                              _formatCurrency(ticket.price * entry.value),
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24, color: AppColors.borderDefault),

                    // Data Diri
                    Text(
                      'Data Diri',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    _buildConfirmDetailRow('Nama Lengkap', "${_firstNameController.text} ${_lastNameController.text}".trim()),
                    const SizedBox(height: 10),
                    _buildConfirmDetailRow('Email', _emailController.text),
                    const SizedBox(height: 10),
                    _buildConfirmDetailRow('Nomor Telepon', _phoneController.text),
                    const SizedBox(height: 10),
                    _buildConfirmDetailRow('Nomor Identitas', _nikController.text),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rincian Biaya Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rincian Biaya',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              ...widget.selectedQuantities.entries.map((entry) {
                if (entry.value <= 0) return Container();
                final ticket = widget.event.tickets.firstWhere((t) => t.id == entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.value}x ${ticket.name}',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatCurrency(ticket.price * entry.value),
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 20, color: AppColors.borderDefault),
              _buildPriceRow('Subtotal Tiket', _apiSubTotal),
              const SizedBox(height: 8),
              _buildPriceRow('PPN (10%)', _apiTaxAmount),
              const SizedBox(height: 8),
              _buildPriceRow('Biaya Admin', _apiAdminFee),
              const SizedBox(height: 8),
              _buildPriceRow('Biaya Platform', _apiPlatformFee),
              const Divider(height: 20, color: AppColors.borderDefault),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Bayar',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    _formatCurrency(_apiGrandTotal),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metode Pembayaran Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Metode Pembayaran',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedMethodName ?? 'Pilih Metode Pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Actions
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _startOrderOnServer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Lanjut',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3;
              });
              _scrollToTop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Kembali',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatIndonesianDate(DateTime dateTime) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final dayName = days[dateTime.weekday % 7];
    final day = dateTime.day;
    final monthName = months[dateTime.month - 1];
    final year = dateTime.year;
    
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$dayName, $day $monthName $year ($hour:$minute WIB)';
  }

  Widget _buildRichInstructionText(String text) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;
    
    for (final Match match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black,
            height: 1.4,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          height: 1.4,
        ),
      ));
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black,
          height: 1.4,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildPriceRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          _formatCurrency(amount),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 5: Detail Tagihan / Halaman Bayar
  // ─────────────────────────────────────────────
  Widget _buildBillDetailStep() {
    final va = _getVirtualAccountNumber();
    final grandTotal = _createdGrandTotal ?? _apiGrandTotal;
    final instructions = _getPaymentInstructions();
    final expiresAt = _expiresAt ?? DateTime.now().add(const Duration(minutes: 15));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main unified card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Poster Image with overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: widget.event.posterImage != null && widget.event.posterImage!.isNotEmpty
                        ? Image.network(
                            widget.event.posterImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          )
                        : Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.event.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.venue,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Timer Section
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Masih ada waktu untuk menyelesaikan pembayaran',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, color: AppColors.bluePrimary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimerText(_secondsRemaining),
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Batas waktu untuk melakukan pembayaran',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatIndonesianDate(expiresAt),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jika melewati batas waktu, pesanan Anda akan dibatalkan otomatis.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 24, color: AppColors.borderDefault),
                    
                    // 3. Payment Details Box (border box inside)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Metode Pembayaran',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              // Logo image or fallback
                              Container(
                                width: 44,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[200]!, width: 0.8),
                                ),
                                child: _selectedMethodLogo != null && _selectedMethodLogo!.isNotEmpty && !_selectedMethodLogo!.endsWith('.svg')
                                    ? Image.network(
                                        _selectedMethodLogo!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildPaymentLogoFallback(_selectedMethodCode ?? '', _selectedMethodName ?? ''),
                                      )
                                    : _buildPaymentLogoFallback(_selectedMethodCode ?? '', _selectedMethodName ?? ''),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nomor Virtual Account',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                va,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _copyToClipboard(va),
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy, size: 14, color: AppColors.bluePrimary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Salin',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.bluePrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.borderDefault),
                          Text(
                            'Total Pembayaran',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(grandTotal),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.bluePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 4. Detail Pesanan Section
                    Text(
                      'Detail Pesanan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Order ID', _createdTrxId ?? ''),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Tanggal Event',
                      '${widget.event.date} • ${widget.event.time.isNotEmpty ? widget.event.time : "19.00 - 21.00 WIB"}',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 5. Actions Buttons (Konfirmasi Pembayaran & Batalkan Pesanan)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _showConfirmPaymentDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Konfirmasi Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Batalkan Pesanan?'),
                              content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tidak'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _cancelOrderOnServer();
                                  },
                                  child: const Text('Ya, Batalkan'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Batalkan Pesanan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Second card: Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Intruksi Pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ...instructions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Expanded(
                        child: _buildRichInstructionText(entry.value),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
