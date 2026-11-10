import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/cart_item_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/order_history_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/smart_image.dart';

/// Màn hình Giỏ hàng & Thanh toán (Chọn Hình thức nhận món, Validate SĐT/Địa chỉ, Ghi chú Barista, Voucher, VNPAY/COD)
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _checkoutFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(
    text: 'Đại học FPT Cần Thơ, 600 Nguyễn Văn Cừ nối dài, Q. Ninh Kiều',
  );
  final _noteController = TextEditingController();
  bool _didPrefillPhone = false;

  final List<String> _quickNotes = const [
    'Để đá riêng',
    'Ít ngọt dễ uống',
    'Thêm giấy ăn & ống hút',
    'Gọi điện khi tới nơi',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Validate Số điện thoại Việt Nam (10 chữ số, bắt đầu bằng 03, 05, 07, 08, 09)
  String? _validatePhone(String? value) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return 'Vui lòng nhập số điện thoại liên hệ nhận món.';
    }
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
    if (!phoneRegex.hasMatch(clean)) {
      return 'Số điện thoại không hợp lệ (Gồm 10 số, VD: 0912345678).';
    }
    return null;
  }

  /// Validate Địa chỉ giao hàng / Số bàn
  String? _validateAddress(String? value, String deliveryType) {
    final clean = (value ?? '').trim();
    if (deliveryType == 'Giao tận nơi') {
      if (clean.isEmpty) {
        return 'Vui lòng nhập địa chỉ giao hàng chi tiết.';
      }
      if (clean.length < 5) {
        return 'Địa chỉ quá ngắn, vui lòng ghi rõ số nhà / đường / tòa nhà.';
      }
    } else {
      if (clean.isEmpty) {
        return 'Vui lòng nhập số bàn hoặc khung giờ đến lấy tại quầy.';
      }
    }
    return null;
  }

  void _appendQuickNote(String tag) {
    final current = _noteController.text.trim();
    if (current.contains(tag)) return;
    setState(() {
      _noteController.text = current.isEmpty ? tag : '$current, $tag';
    });
  }

  void _handleCheckout(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    if (!authVM.isLoggedIn) {
      AuthGuard.showLoginRequiredDialog(context, actionMessage: 'tiến hành thanh toán và đặt hàng');
      return;
    }

    // Kiểm tra Validate SĐT & Địa chỉ giao hàng trước khi cho phép thanh toán
    if (!(_checkoutFormKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại Số điện thoại và Địa chỉ nhận món!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cartVM = context.read<CartViewModel>();
    final userId = authVM.currentUser?.uid ?? 'guest';
    final customerName = authVM.currentUser?.displayName ?? 'Khách vãng lai';
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final note = _noteController.text.trim();

    if (cartVM.selectedPaymentMethod == 'VNPAY Sandbox') {
      // 1. Chuyển sang Cổng thanh toán VNPAY Sandbox
      final paymentSuccess = await Navigator.pushNamed(
        context,
        AppRoutes.vnpay,
        arguments: {
          'amount': cartVM.totalAmount,
          'orderInfo': 'Thanh toan don hang LOWLAND Coffee ($phone)',
        },
      );

      if (paymentSuccess == true && context.mounted) {
        final success = await cartVM.checkout(
          userId,
          customerName: customerName,
          paymentMethod: 'VNPAY Sandbox (Đã thanh toán)',
          receiverPhone: phone,
          deliveryAddress: address,
          orderNote: note,
        );
        if (success && context.mounted) {
          context.read<OrderHistoryViewModel>().loadOrders();
          _showOrderSuccessDialog(context, 'Thanh toán qua VNPAY Sandbox thành công!');
        }
      }
    } else {
      // 2. Thanh toán Tiền mặt (COD)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.fact_check_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Xác nhận đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Hình thức: ${cartVM.deliveryType}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('• SĐT người nhận: $phone', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text('• Địa chỉ/Bàn: $address', style: const TextStyle(fontSize: 13)),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('• Ghi chú: $note', style: const TextStyle(fontSize: 12, color: AppColors.accentDark)),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán (COD):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    CurrencyFormatter.format(cartVM.totalAmount),
                    style: AppTextStyles.price,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kiểm tra lại', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await cartVM.checkout(
                  userId,
                  customerName: customerName,
                  paymentMethod: 'Tiền mặt (COD)',
                  receiverPhone: phone,
                  deliveryAddress: address,
                  orderNote: note,
                );
                if (success && context.mounted) {
                  context.read<OrderHistoryViewModel>().loadOrders();
                  _showOrderSuccessDialog(context, 'Đơn hàng của bạn đã được chuyển xuống quầy Barista!');
                }
              },
              child: const Text('Xác nhận đặt món'),
            ),
          ],
        ),
      );
    }
  }

  void _showOrderSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (successCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 58,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đặt hàng thành công!',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Barista đang chuẩn bị thức uống cho bạn. Bạn có thể theo dõi tiến độ Realtime tại mục Lịch sử đơn hàng!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(successCtx);
              Navigator.pushNamed(context, AppRoutes.orderHistory);
            },
            child: const Text('Xem tiến độ đơn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(successCtx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.main,
                (route) => false,
              );
            },
            child: const Text('Về thực đơn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final authVM = context.watch<AuthViewModel>();

    // Tự động điền SĐT của user nếu đã có trong hồ sơ
    if (!_didPrefillPhone && authVM.currentUser?.phoneNumber != null && authVM.currentUser!.phoneNumber!.isNotEmpty) {
      _phoneController.text = authVM.currentUser!.phoneNumber!;
      _didPrefillPhone = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Giỏ hàng & Thanh toán'),
        actions: [
          if (cartVM.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa toàn bộ giỏ',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa giỏ hàng'),
                    content: const Text('Bạn có chắc chắn muốn làm trống toàn bộ giỏ hàng?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () {
                          Navigator.pop(ctx);
                          cartVM.clearCart();
                        },
                        child: const Text('Xóa hết'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartVM.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Giỏ hàng của bạn đang trống',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy chọn những ly cà phê hoặc thức uống yêu thích nhé!',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Khám phá thực đơn ngay',
                    width: 240,
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.main),
                  ),
                ],
              ),
            )
          : Form(
              key: _checkoutFormKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Chọn Hình thức nhận món (Giao tận nơi / Dùng tại quán)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('1. Hình thức & Thông tin nhận món', style: AppTextStyles.subtitle),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDeliveryTypeCard(
                                title: 'Giao tận nơi',
                                subtitle: 'Miễn phí ship',
                                icon: Icons.delivery_dining_rounded,
                                isSelected: cartVM.deliveryType == 'Giao tận nơi',
                                onTap: () {
                                  cartVM.setDeliveryType('Giao tận nơi');
                                  if (_addressController.text.contains('Bàn số')) {
                                    _addressController.text =
                                        'Đại học FPT Cần Thơ, 600 Nguyễn Văn Cừ nối dài, Q. Ninh Kiều';
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDeliveryTypeCard(
                                title: 'Tại quán / Tự lấy',
                                subtitle: 'Nhận sau 5 phút',
                                icon: Icons.storefront_rounded,
                                isSelected: cartVM.deliveryType == 'Dùng tại quán / Tự lấy',
                                onTap: () {
                                  cartVM.setDeliveryType('Dùng tại quán / Tự lấy');
                                  if (_addressController.text.contains('Đại học FPT Cần Thơ')) {
                                    _addressController.text = 'Bàn số 05 - Tầng 1 (LOWLAND Flagship)';
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Số điện thoại người nhận (Bắt buộc + Validate 10 số)
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại nhận hàng *',
                            hintText: 'Nhập SĐT 10 số (VD: 0912345678)',
                            prefixIcon: const Icon(Icons.phone_in_talk_rounded, size: 19, color: AppColors.primary),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceCream.withValues(alpha: 0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Địa chỉ giao hàng hoặc Số bàn
                        TextFormField(
                          controller: _addressController,
                          validator: (val) => _validateAddress(val, cartVM.deliveryType),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: cartVM.deliveryType == 'Giao tận nơi'
                                ? 'Địa chỉ giao hàng *'
                                : 'Số bàn / Ghi chú lấy tại quầy *',
                            hintText: cartVM.deliveryType == 'Giao tận nơi'
                                ? 'Số nhà, tên đường, tòa nhà...'
                                : 'Ví dụ: Bàn số 05 hoặc Lấy mang đi lúc 14:30',
                            prefixIcon: Icon(
                              cartVM.deliveryType == 'Giao tận nơi'
                                  ? Icons.location_on_outlined
                                  : Icons.table_restaurant_outlined,
                              size: 19,
                              color: AppColors.primary,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceCream.withValues(alpha: 0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ghi chú cho Barista
                        TextFormField(
                          controller: _noteController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Ghi chú cho Barista (Tùy chọn)',
                            hintText: 'Ví dụ: Để đá riêng, ít ngọt, lấy thêm túi giữ nhiệt...',
                            prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.accent),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceCream.withValues(alpha: 0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Gợi ý ghi chú nhanh 1 chạm
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _quickNotes.map((tag) {
                            return InkWell(
                              onTap: () => _appendQuickNote(tag),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCream,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '+ $tag',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Danh sách các món đã chọn
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('2. Danh sách món đã chọn', style: AppTextStyles.subtitle),
                  ),
                  ...cartVM.items.map((item) => _buildCartItemCard(context, item, cartVM)),
                  const SizedBox(height: 8),

                  // 3. Mục Mã giảm giá (Vouchers)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cartVM.selectedVoucher != null ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.confirmation_number_rounded, color: AppColors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mã ưu đãi LOWLAND',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                cartVM.selectedVoucher != null
                                    ? 'Đang dùng: ${cartVM.selectedVoucher!.code} (-${CurrencyFormatter.format(cartVM.discountAmount)})'
                                    : 'Chọn hoặc nhập mã giảm giá',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cartVM.selectedVoucher != null
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: cartVM.selectedVoucher != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.vouchers),
                          child: Text(
                            cartVM.selectedVoucher != null ? 'Đổi mã' : 'Chọn / Nhập mã',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Mục Phương thức thanh toán (VNPay Sandbox & Tiền mặt)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('3. Phương thức thanh toán', style: AppTextStyles.subtitle),
                        const SizedBox(height: 12),

                        // Tiền mặt COD
                        InkWell(
                          onTap: () => cartVM.setPaymentMethod('Tiền mặt (COD)'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cartVM.selectedPaymentMethod == 'Tiền mặt (COD)'
                                  ? AppColors.surfaceCream
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cartVM.selectedPaymentMethod == 'Tiền mặt (COD)'
                                    ? AppColors.primary
                                    : AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.payments_outlined, color: AppColors.primary),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tiền mặt khi nhận hàng (COD)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Thanh toán trực tiếp cho Shipper hoặc Thu ngân',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  cartVM.selectedPaymentMethod == 'Tiền mặt (COD)'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: cartVM.selectedPaymentMethod == 'Tiền mặt (COD)'
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Cổng VNPAY Sandbox
                        InkWell(
                          onTap: () => cartVM.setPaymentMethod('VNPAY Sandbox'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                                  ? const Color(0xFFE6F0FA)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                                    ? const Color(0xFF005BAA)
                                    : AppColors.border.withValues(alpha: 0.5),
                                width: cartVM.selectedPaymentMethod == 'VNPAY Sandbox' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005BAA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VNPAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Cổng VNPAY Sandbox',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'NCB / QR',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'Thẻ ATM nội địa (NCB 9704198526191432198) / QR',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                                      ? const Color(0xFF005BAA)
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Tóm tắt đơn hàng (Chi tiết thanh toán)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('4. Chi tiết thanh toán', style: AppTextStyles.subtitle),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tạm tính (${cartVM.totalItemCount} món):', style: AppTextStyles.body),
                            Text(CurrencyFormatter.format(cartVM.subtotal), style: AppTextStyles.body),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giảm giá voucher:', style: AppTextStyles.body),
                            Text(
                              '-${CurrencyFormatter.format(cartVM.discountAmount)}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cartVM.deliveryType == 'Giao tận nơi' ? 'Phí giao hàng:' : 'Phí phục vụ tại quán:',
                              style: AppTextStyles.body,
                            ),
                            const Text('Miễn phí (0đ)', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              CurrencyFormatter.format(cartVM.totalAmount),
                              style: AppTextStyles.priceLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
      bottomNavigationBar: cartVM.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                      ? 'Thanh toán VNPAY • ${CurrencyFormatter.format(cartVM.totalAmount)}'
                      : 'Đặt hàng (COD) • ${CurrencyFormatter.format(cartVM.totalAmount)}',
                  icon: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                      ? Icons.credit_card_rounded
                      : Icons.check_circle_outline_rounded,
                  onPressed: () => _handleCheckout(context),
                ),
              ),
            ),
    );
  }

  Widget _buildDeliveryTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItemModel item, CartViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh món
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: SmartImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tên món, tùy chọn size/đường/đá/topping
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name.toLowerCase().contains('bánh')
                      ? 'Kích cỡ: Tiêu chuẩn'
                      : 'Size ${item.selectedSize} | Đường ${item.selectedSugar}% | Đá ${item.selectedIce}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                if (item.selectedToppings.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Topping: ${item.selectedToppings.join(', ')}',
                    style: const TextStyle(fontSize: 11, color: AppColors.accentDark),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(item.totalPrice),
                  style: AppTextStyles.price,
                ),
              ],
            ),
          ),

          // Bộ tăng giảm số lượng (+ / -)
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () {
                  if (item.id != null) {
                    vm.removeItem(item.id!);
                  }
                },
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => vm.updateQuantity(item, item.quantity - 1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.remove, size: 16, color: AppColors.primary),
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => vm.updateQuantity(item, item.quantity + 1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.add, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
