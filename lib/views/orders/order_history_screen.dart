import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/order_history_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Lịch sử đơn hàng (Lưu trữ SQLite)
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // Phân quyền: Khách chưa đăng nhập không thể xem lịch sử đơn hàng
    if (!authVM.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bạn chưa đăng nhập',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng đăng nhập để theo dõi tiến độ pha chế, giao hàng và xem lại các hóa đơn đã đặt!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Đăng nhập ngay',
                  width: 200,
                  icon: Icons.login_rounded,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final orderVM = context.watch<OrderHistoryViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
      ),
      body: orderVM.orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có đơn hàng nào',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Các đơn hàng hoàn thành sẽ được lưu trữ tại đây',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Đặt món ngay',
                    width: 180,
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.main),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orderVM.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = orderVM.orders[index];
                DateTime? orderDate = DateTime.tryParse(order.orderDate);
                final formattedDate = orderDate != null
                    ? DateFormat('HH:mm - dd/MM/yyyy').format(orderDate)
                    : order.orderDate;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withOpacity(0.7)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Mã đơn + Trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: order.paymentMethod.contains('VNPAY') ? Colors.blue.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: order.paymentMethod.contains('VNPAY') ? Colors.blue.shade200 : Colors.amber.shade200,
                              ),
                            ),
                            child: Text(
                              order.paymentMethod,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: order.paymentMethod.contains('VNPAY') ? const Color(0xFF005BAA) : Colors.brown.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Danh sách các món trong đơn
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${item.quantity}x ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${item.name} (Size ${item.selectedSize})',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.totalPrice),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )),

                      const Divider(height: 20),

                      // Tóm tắt tiền
                      if (order.discount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giảm giá (${order.voucherCode ?? "Voucher"}):',
                              style: const TextStyle(fontSize: 12, color: AppColors.success),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(order.discount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            CurrencyFormatter.format(order.totalAmount),
                            style: AppTextStyles.priceLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

