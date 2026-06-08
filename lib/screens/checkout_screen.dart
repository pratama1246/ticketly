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
  int _currentStep = 1; // Step 1: T&C, 2: Payment Method, 3: Confirmation, 4: Bill Details
  bool _isLoading = false;

  // Step 1: Syarat & Ketentuan
  bool _isTnCAccepted = false;

  // Step 2: Metode Pembayaran
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoadingMethods = true;
  String? _selectedMethodCode;
  String? _selectedMethodName;
  String? _selectedMethodType;
  String? _selectedMethodLogo;

  // Step 3: Data Diri Form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();

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

  // Timers
  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15:00 minutes local countdown for Steps 2-3

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPaymentMethods();
    _calculatePricing();
    _startLocalTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  void _startLocalTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _countdownTimer?.cancel();
            _handleSessionExpired();
          }
        });
      }
    });
  }

  void _handleSessionExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Waktu Habis',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Sesi checkout Anda telah berakhir. Silakan ulangi pemesanan Anda.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to event detail
            },
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
        _nameController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        // If profile details don't have phone/NIK, leave empty for user input
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
              _isLoadingMethods = false;
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
        _isLoadingMethods = false;
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
    if (!_formKey.currentState!.validate()) return;
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
      'first_name': _nameController.text.trim(),
      'last_name': '',
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
          
          // Re-calculate remaining seconds based on server expiry
          _secondsRemaining = parsedExpiresAt.difference(DateTime.now()).inSeconds;
          if (_secondsRemaining < 0) _secondsRemaining = 0;

          _currentStep = 4;
          _isLoading = false;
        });
        _startLocalTimer();
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
                          ),
                          child: const Text('Coba Lagi'),
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
                          ),
                          child: const Text('Ya, Sudah Bayar'),
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
        'Pilih menu bayar / scan QRIS.',
        'Masukkan nomor transaksi atau pindai QR code.',
        'Periksa detail tagihan Anda.',
        'Masukkan PIN Anda untuk menyelesaikan pembayaran.'
      ];
    }
    return [
      'Buka aplikasi Mobile Banking atau ATM Anda.',
      'Pilih menu Transfer Virtual Account.',
      'Masukkan Nomor VA ${_getVirtualAccountNumber()}.',
      'Periksa detail nama dan total tagihan.',
      'Masukkan PIN Anda dan simpan bukti transaksi.'
    ];
  }

  // Brand badges colors helper
  Color _getBrandColor() {
    switch (_selectedMethodCode) {
      case 'bca': return const Color(0xFF005CAA);
      case 'bri': return const Color(0xFF003882);
      case 'bni': return const Color(0xFFE55300);
      case 'mandiri_bill': return const Color(0xFFFFC600);
      case 'gopay': return const Color(0xFF00AED6);
      case 'ovo': return const Color(0xFF4C2A86);
      case 'dana': return const Color(0xFF108EE9);
      case 'shopeepay': return const Color(0xFFEE4D2D);
      case 'allobank': return const Color(0xFF00B1AF);
      case 'akulaku': return const Color(0xFFE11919);
      default: return AppColors.bluePrimary;
    }
  }

  // Helper widget to build horizontal stepper bar
  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, Icons.check, 'S&K'),
          _buildStepDivider(1),
          _buildStepCircle(2, Icons.payment, 'Metode'),
          _buildStepDivider(2),
          _buildStepCircle(3, Icons.assignment, 'Konfirmasi'),
          _buildStepDivider(3),
          _buildStepCircle(4, Icons.receipt_long, 'Bayar'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNum, IconData iconData, String label) {
    final isCompleted = _currentStep > stepNum;
    final isActive = _currentStep == stepNum;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFDCFCE7)
                : (isActive ? AppColors.bluePrimary : Colors.grey[200]),
            shape: BoxShape.circle,
            border: isCompleted
                ? Border.all(color: const Color(0xFF22C55E), width: 1)
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : iconData,
            size: 16,
            color: isCompleted
                ? const Color(0xFF16A34A)
                : (isActive ? Colors.white : Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepAfter) {
    final isCompleted = _currentStep > stepAfter;
    return Container(
      width: 48,
      height: 2,
      color: isCompleted ? const Color(0xFF22C55E) : Colors.grey[300],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        title: Text(
          _currentStep == 1
              ? 'Syarat & Ketentuan'
              : (_currentStep == 2
                  ? 'Metode Pembayaran'
                  : 'Konfirmasi Pesanan'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              setState(() {
                _currentStep--;
              });
            } else if (_currentStep == 4) {
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
              _buildStepIndicator(),
              Expanded(
                child: _isLoadingCalculation
                    ? const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildStepContent(),
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
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
        return _buildPaymentMethodStep();
      case 3:
        return _buildConfirmOrderStep();
      case 4:
        return _buildBillDetailStep();
      default:
        return Container();
    }
  }

  // ─────────────────────────────────────────────
  // STEP 1: Syarat & Ketentuan
  // ─────────────────────────────────────────────
  Widget _buildTnCStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                'Syarat & Ketentuan Pembelian',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Render Terms list dynamically
              ..._parseHtmlTerms(widget.event.description).map((term) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            term,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTnCAccepted ? AppColors.bluePrimary : Colors.grey[300],
            ),
            child: const Text('Lanjut'),
          ),
        ),
      ],
    );
  }

  List<String> _parseHtmlTerms(String html) {
    if (html.isEmpty) {
      return [
        'Tiket yang sudah dibeli tidak dapat ditukar atau dikembalikan.',
        'Satu tiket hanya berlaku untuk satu orang.',
        'Penyelenggara berhak melarang masuk jika terjadi pelanggaran aturan.',
      ];
    }
    // Clean html tags to plain bullets
    String clean = html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    // Split by lines or lists
    final list = clean.split(RegExp(r'\r\n|\n|\•'));
    return list
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.length > 5)
        .toList();
  }

  // ─────────────────────────────────────────────
  // STEP 2: Metode Pembayaran
  // ─────────────────────────────────────────────
  Widget _buildPaymentMethodStep() {
    final ewallets = _paymentMethods.where((m) => m['type'] == 'ewallet').toList();
    final vas = _paymentMethods.where((m) => m['type'] == 'virtual_account').toList();
    final others = _paymentMethods.where((m) => m['type'] == 'other').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floating timer box
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFBBF24), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFFBBF24), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Sisa waktu  ',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  _formatTimerText(_secondsRemaining),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

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

        // Action buttons
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedMethodCode != null
                ? () {
                    setState(() {
                      _currentStep = 3;
                    });
                  }
                : null,
            child: const Text('Lanjut'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
            ),
            child: const Text('Batal'),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFBBF24), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sisa waktu  ',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    _formatTimerText(_secondsRemaining),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Event Summary card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.event.posterImage != null && widget.event.posterImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.event.posterImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.name,
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
                            widget.event.date,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
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
                              widget.event.venue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
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
          const SizedBox(height: 20),

          // Tickets List detail
          Text(
            'Tiket yang Dipesan',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.selectedQuantities.entries.map((entry) {
            if (entry.value <= 0) return Container();
            final ticket = widget.event.tickets.firstWhere((t) => t.id == entry.key);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.value}x  ${ticket.name}',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatCurrency(ticket.price * entry.value),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Form Data Diri
          Text(
            'Data Diri Pemesan',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormFieldLabel('Nama Lengkap'),
                TextFormField(
                  controller: _nameController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                  decoration: const InputDecoration(hintText: 'Nama lengkap sesuai identitas'),
                ),
                const SizedBox(height: 12),

                _buildFormFieldLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val == null || !val.contains('@') ? 'Masukkan alamat email valid' : null,
                  decoration: const InputDecoration(hintText: 'nama@domain.com'),
                ),
                const SizedBox(height: 12),

                _buildFormFieldLabel('Nomor Telepon'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
                  decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
                ),
                const SizedBox(height: 12),

                _buildFormFieldLabel('Nomor Identitas (NIK KTP)'),
                TextFormField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.length < 10 ? 'Masukkan nomor identitas yang valid' : null,
                  decoration: const InputDecoration(hintText: 'Masukkan 16 digit NIK KTP'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Price Details Card
          Text(
            'Rincian Biaya',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              children: [
                _buildPriceRow('Subtotal Tiket', _apiSubTotal),
                const SizedBox(height: 8),
                _buildPriceRow('PPN (11%)', _apiTaxAmount),
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
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
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

          // Selected Payment Method Detail Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment_outlined, color: AppColors.bluePrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode Pembayaran',
                        style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                      ),
                      Text(
                        _selectedMethodName ?? 'Pilih Metode Pembayaran',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
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
              child: const Text('Lanjut'),
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
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
              ),
              child: const Text('Batal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
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
  // STEP 4: Detail Tagihan
  // ─────────────────────────────────────────────
  Widget _buildBillDetailStep() {
    final va = _getVirtualAccountNumber();
    final grandTotal = _createdGrandTotal ?? _apiGrandTotal;
    final instructions = _getPaymentInstructions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sisa waktu notice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                'Masih ada waktu untuk menyelesaikan pembayaran',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Big Clock Icon Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: AppColors.bluePrimary, size: 36),
                  const SizedBox(width: 12),
                  Text(
                    _formatTimerText(_secondsRemaining),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Batas waktu untuk melakukan pembayaran adalah 15 menit dari pembuatan pesanan. Jika melewati batas waktu, pesanan Anda akan dibatalkan otomatis.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Details Box matching mockup
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
              // Logo + Name
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (_selectedMethodCode ?? 'VA').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _getBrandColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedMethodName ?? 'Virtual Account',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.borderDefault),

              // Nomor VA
              Text(
                'Nomor Virtual Account',
                style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    va,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                            fontSize: 11,
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

              // Total Pembayaran
              Text(
                'Total Pembayaran',
                style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(grandTotal),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Detail Pesanan Box
        Text(
          'Detail Pesanan',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            children: [
              _buildDetailRow('Order ID', _createdTrxId ?? ''),
              const SizedBox(height: 8),
              _buildDetailRow('Tanggal Event', '${widget.event.date} - ${widget.event.time}'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Instructions Accordion
        Text(
          'Instruksi Pembayaran',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 28),

        // Actions
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _showConfirmPaymentDialog,
            child: const Text('Konfirmasi Pembayaran'),
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
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
            ),
            child: const Text('Batalkan Pesanan'),
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
