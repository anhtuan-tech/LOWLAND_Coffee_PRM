import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Cổng thanh toán VNPAY Sandbox (Môi trường Test Thử nghiệm)
class VNPaySandboxScreen extends StatefulWidget {
  final double amount;
  final String orderInfo;

  const VNPaySandboxScreen({
    super.key,
    required this.amount,
    required this.orderInfo,
  });

  @override
  State<VNPaySandboxScreen> createState() => _VNPaySandboxScreenState();
}

class _VNPaySandboxScreenState extends State<VNPaySandboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Thẻ ATM Sandbox
  final _cardNumberController = TextEditingController(text: '9704198526191432198');
  final _cardHolderController = TextEditingController(text: 'NGUYEN VAN A');
  final _cardDateController = TextEditingController(text: '07/15');
  final _otpController = TextEditingController(text: '123456');

  String _selectedBank = 'NCB';
  bool _isProcessing = false;
  String _processMessage = '';

  // Countdown timer 15 phút
  int _secondsRemaining = 900;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardDateController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Mô phỏng xử lý thanh toán qua VNPAY Sandbox
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _processMessage = 'Đang kết nối cổng thanh toán VNPAY Sandbox...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _processMessage = 'Đang xác thực thông tin thẻ & ngân hàng $_selectedBank...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _processMessage = 'Xác thực mã OTP bảo mật thành công...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Thành công
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán VNPAY thành công!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Số tiền: ${CurrencyFormatter.format(widget.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mã giao dịch: VNPAY-TEST-99214\nMôi trường thử nghiệm Sandbox',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005BAA)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Trả về kết quả thành công
            },
            child: const Text('Xác nhận & Hoàn tất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BAA), // Xanh dương thương hiệu VNPAY
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VNPAY',
                style: TextStyle(
                  color: Color(0xFF005BAA),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Cổng thanh toán Sandbox',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thẻ Thông tin giao dịch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đơn vị thụ hưởng:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const Text(
                        'LOWLAND COFFEE VN',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số tiền thanh toán:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFED1C24), // Đỏ nổi bật
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thời gian giữ đơn:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatTimer(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar chọn phương thức: Thẻ ATM / QR
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF005BAA),
                labelColor: const Color(0xFF005BAA),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.credit_card), text: 'Thẻ ATM / Tài khoản'),
                  Tab(icon: Icon(Icons.qr_code_scanner), text: 'Quét VNPAY-QR'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nội dung theo Tab
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Thẻ ATM nội địa (NCB Sandbox)
                  _buildCardPaymentTab(),

                  // TAB 2: VNPAY-QR
                  _buildQrPaymentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Sandbox Info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF005BAA), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Môi trường Sandbox VNPAY: Đã điền sẵn thông tin thẻ thử nghiệm NCB.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF005BAA), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chọn Ngân hàng
          const Text(
            'Chọn ngân hàng thử nghiệm:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: const [
              DropdownMenuItem(value: 'NCB', child: Text('NCB - Ngân hàng Quốc Dân (Sandbox)')),
              DropdownMenuItem(value: 'VCB', child: Text('Vietcombank')),
              DropdownMenuItem(value: 'TCB', child: Text('Techcombank')),
              DropdownMenuItem(value: 'BIDV', child: Text('BIDV')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedBank = val);
            },
          ),
          const SizedBox(height: 12),

          // Số thẻ
          const Text('Số thẻ *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.credit_card, size: 20),
            ),
          ),
          const SizedBox(height: 12),

          // Tên chủ thẻ & Ngày hết hạn
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tên chủ thẻ *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _cardHolderController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngày phát hành *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _cardDateController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mã OTP Sandbox
          const Text('Mã OTP xác thực *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: _otpController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.security, size: 20),
            ),
          ),
          const Spacer(),

          // Nút thanh toán
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAA),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isProcessing ? null : _processPayment,
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(_processMessage, style: const TextStyle(fontSize: 12)),
                    ],
                  )
                : Text(
                    'Xác nhận thanh toán ${CurrencyFormatter.format(widget.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPaymentTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mô phỏng mã QR VNPAY
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF005BAA), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 160,
                  color: Color(0xFF005BAA),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quét mã với App Ngân hàng hoặc Ví VNPAY',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nút mô phỏng thanh toán thành công
          CustomButton(
            text: 'Mô phỏng Quét mã thành công (Test)',
            icon: Icons.check_circle_outline,
            isLoading: _isProcessing,
            onPressed: _processPayment,
          ),
        ],
      ),
    );
  }
}

