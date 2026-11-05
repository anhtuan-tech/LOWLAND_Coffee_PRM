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
import '../../widgets/custom_button.dart';

/// Màn hình Giỏ hàng (SQLite CRUD, Áp dụng Voucher, Cổng thanh toán VNPAY Sandbox, Đặt hàng)
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _handleCheckout(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    if (!authVM.isLoggedIn) {
      AuthGuard.showLoginRequiredDialog(context, actionMessage: 'tiến hành thanh toán và đặt hàng');
      return;
    }

    final cartVM = context.read<CartViewModel>();
    final userId = authVM.currentUser?.uid ?? 'guest';
    final customerName = authVM.currentUser?.displayName ?? 'Khách vãng lai';

    if (cartVM.selectedPaymentMethod == 'VNPAY Sandbox') {
      // 1. Chuyển sang Cổng thanh toán VNPAY Sandbox
      final paymentSuccess = await Navigator.pushNamed(
        context,
        AppRoutes.vnpay,
        arguments: {
          'amount': cartVM.totalAmount,
          'orderInfo': 'Thanh toán đơn hàng LOWLAND Coffee',
        },
      );

      if (paymentSuccess == true && context.mounted) {
        final success = await cartVM.checkout(
          userId,
          customerName: customerName,
          paymentMethod: 'VNPAY Sandbox (Đã thanh toán)',
        );
        if (success && context.mounted) {
          _showOrderSuccessDialog(context, 'Thanh toán qua VNPAY Sandbox thành công!');
        }
      }
    } else {
      // 2. Thanh toán Tiền mặt (COD)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận đặt hàng COD'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bạn chọn thanh toán bằng Tiền mặt khi nhận hàng (COD).'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await cartVM.checkout(
                  userId,
                  customerName: customerName,
                  paymentMethod: 'Tiền mặt (COD)',
                );
                if (success && context.mounted) {
                  _showOrderSuccessDialog(context, 'Đơn hàng của bạn đã được tiếp nhận!');
                }
              },
              child: const Text('Xác nhận đặt'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.success,
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
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quán đang chuẩn bị món cho bạn. Đơn đã được cập nhật Realtime lên hệ thống!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
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
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Giỏ hàng của bạn'),
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
                    content: const Text('Bạn có chắc chắn muốn làm trống giỏ hàng?'),
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
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Danh sách các món trong giỏ (SQLite)
                ...cartVM.items.map((item) => _buildCartItemCard(context, item, cartVM)),
                const SizedBox(height: 16),

                // Mục Mã giảm giá (Vouchers)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mã giảm giá',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              cartVM.selectedVoucher != null
                                  ? 'Đang áp dụng: ${cartVM.selectedVoucher!.code} (-${CurrencyFormatter.format(cartVM.discountAmount)})'
                                  : 'Chọn hoặc nhập mã ưu đãi',
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
                          cartVM.selectedVoucher != null ? 'Đổi mã' : 'Chọn mã',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mục Phương thức thanh toán (VNPay Sandbox & Tiền mặt)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phương thức thanh toán', style: AppTextStyles.subtitle),
                      const SizedBox(height: 12),

                      // Tiền mặt COD
                      InkWell(
                        onTap: () => cartVM.setPaymentMethod('Tiền mặt (COD)'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cartVM.selectedPaymentMethod == 'Tiền mặt (COD)'
                                ? AppColors.surfaceCream
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cartVM.selectedPaymentMethod == 'Tiền mặt (COD)'
                                  ? AppColors.primary
                                  : AppColors.border.withOpacity(0.5),
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
                                      'Thanh toán trực tiếp khi nhận nước/bánh',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: 'Tiền mặt (COD)',
                                groupValue: cartVM.selectedPaymentMethod,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) cartVM.setPaymentMethod(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Cổng VNPAY Sandbox
                      InkWell(
                        onTap: () => cartVM.setPaymentMethod('VNPAY Sandbox'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                                ? const Color(0xFFE6F0FA)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cartVM.selectedPaymentMethod == 'VNPAY Sandbox'
                                  ? const Color(0xFF005BAA)
                                  : AppColors.border.withOpacity(0.5),
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
                                            'Test Môi trường',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Thẻ ATM nội địa (NCB Sandbox) / Quét mã QR',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: 'VNPAY Sandbox',
                                groupValue: cartVM.selectedPaymentMethod,
                                activeColor: const Color(0xFF005BAA),
                                onChanged: (val) {
                                  if (val != null) cartVM.setPaymentMethod(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tóm tắt đơn hàng (Chi tiết thanh toán)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiết thanh toán', style: AppTextStyles.subtitle),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tạm tính:', style: AppTextStyles.body),
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí phục vụ:', style: AppTextStyles.body),
                          Text('Miễn phí', style: TextStyle(color: AppColors.success)),
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
                const SizedBox(height: 90), // Chừa khoảng trống cho thanh đặt hàng
              ],
            ),
      bottomNavigationBar: cartVM.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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

  Widget _buildCartItemCard(BuildContext context, CartItemModel item, CartViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
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
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceCream,
                  child: const Icon(Icons.coffee, color: AppColors.primary),
                ),
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
                  'Size ${item.selectedSize} | Đường ${item.selectedSugar}% | Đá ${item.selectedIce}%',
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
