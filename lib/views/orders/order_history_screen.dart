import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/order_history_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Lịch sử đơn hàng & Theo dõi Tiến độ Pha chế Realtime
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentUid = context.read<AuthViewModel>().currentUser?.uid;
        context.read<OrderHistoryViewModel>().loadOrders(userId: currentUid);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Mới nhận':
        return Colors.orange.shade800;
      case 'Đang chế biến':
        return Colors.blue.shade700;
      case 'Đang giao':
        return Colors.purple.shade700;
      case 'Hoàn thành':
        return AppColors.success;
      case 'Đã hủy':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'Mới nhận':
        return 0;
      case 'Đang chế biến':
        return 1;
      case 'Đang giao':
        return 2;
      case 'Hoàn thành':
        return 3;
      default:
        return -1;
    }
  }

  /// Thanh tiến độ 4 bước trực quan (Mới nhận -> Pha chế -> Giao -> Hoàn thành)
  Widget _buildOrderProgressTracker(String status) {
    if (status == 'Đã hủy') {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
            SizedBox(width: 6),
            Text(
              'Đơn hàng này đã bị hủy.',
              style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final currentStep = _getStepIndex(status);
    final steps = [
      {'label': 'Mới nhận', 'icon': Icons.receipt_long_rounded},
      {'label': 'Pha chế', 'icon': Icons.coffee_maker_rounded},
      {'label': 'Đang giao', 'icon': Icons.delivery_dining_rounded},
      {'label': 'Hoàn thành', 'icon': Icons.verified_rounded},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = i <= currentStep;
          return Expanded(
            child: Column(
              children: [
                Icon(
                  steps[i]['icon'] as IconData,
                  size: 18,
                  color: isDone ? AppColors.primary : Colors.grey.shade400,
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i]['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                    color: isDone ? AppColors.primary : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, OrderModel order, OrderHistoryViewModel orderVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: Text('Đơn hàng ${order.orderId} đang ở trạng thái "Mới nhận" (quán chưa pha chế). Bạn có chắc chắn muốn hủy đơn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUid = context.read<AuthViewModel>().currentUser?.uid;
              final ok = await orderVM.cancelOrder(order.orderId, userId: currentUid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(duration: const Duration(milliseconds: 1500), 
                  SnackBar(duration: const Duration(milliseconds: 1500), 
                    content: Text(ok ? 'Đã hủy đơn hàng ${order.orderId}' : 'Lỗi khi hủy đơn'),
                    backgroundColor: ok ? AppColors.primary : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

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
                  decoration: const BoxDecoration(
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
        title: const Text('Theo dõi & Lịch sử đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Cập nhật trạng thái đơn mới nhất',
            onPressed: () {
              final currentUid = context.read<AuthViewModel>().currentUser?.uid;
              orderVM.loadOrders(userId: currentUid);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final currentUid = context.read<AuthViewModel>().currentUser?.uid;
          await orderVM.loadOrders(userId: currentUid);
        },
        child: orderVM.orders.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
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
                          'Các đơn hàng của bạn sẽ được cập nhật trạng thái trực tiếp tại đây',
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
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orderVM.orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = orderVM.orders[index];
                  DateTime? orderDate = DateTime.tryParse(order.orderDate)?.toLocal();
                  final formattedDate = orderDate != null
                      ? DateFormat('HH:mm:ss - dd/MM/yyyy').format(orderDate)
                      : order.orderDate;
                  final statusColor = _getStatusColor(order.status);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                            Row(
                              children: [
                                const Icon(Icons.local_cafe_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  order.orderId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                                color: order.paymentMethod.contains('VNPAY')
                                    ? Colors.blue.shade50
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: order.paymentMethod.contains('VNPAY')
                                      ? Colors.blue.shade200
                                      : Colors.amber.shade200,
                                ),
                              ),
                              child: Text(
                                order.paymentMethod,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: order.paymentMethod.contains('VNPAY')
                                      ? const Color(0xFF005BAA)
                                      : Colors.brown.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Thanh tiến độ 4 bước
                        _buildOrderProgressTracker(order.status),

                        // Thông tin nhận hàng & ghi chú nếu có
                        if (order.receiverPhone.isNotEmpty || order.deliveryAddress.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📍 ${order.deliveryType}: ${order.deliveryAddress}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                if (order.receiverPhone.isNotEmpty)
                                  Text(
                                    '📞 SĐT: ${order.receiverPhone}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                if (order.orderNote.isNotEmpty)
                                  Text(
                                    '📝 Ghi chú: ${order.orderNote}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.accentDark),
                                  ),
                              ],
                            ),
                          ),
                        ],

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
                              'Tổng thanh toán:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              CurrencyFormatter.format(order.totalAmount),
                              style: AppTextStyles.price,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Các nút hành động: Hủy đơn (khi Mới nhận) & Đặt lại đơn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (order.status == 'Mới nhận') ...[
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 34),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Hủy đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _confirmCancelOrder(context, order, orderVM),
                              ),
                              const SizedBox(width: 10),
                            ],
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: const Size(0, 34),
                              ),
                              icon: const Icon(Icons.replay_rounded, size: 16),
                              label: const Text('Đặt lại đơn này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                await context.read<CartViewModel>().reorderItems(order.items);
                                if (context.mounted) {
                                  Navigator.pushNamed(context, AppRoutes.cart);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
