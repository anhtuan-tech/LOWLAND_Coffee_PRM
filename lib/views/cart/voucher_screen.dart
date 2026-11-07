import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/cart_viewmodel.dart';

/// Màn hình Ví Mã giảm giá (Vouchers) LOWLAND Coffee (Có ô nhập mã Code tay & Đồng bộ Firestore)
class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartViewModel>().loadVouchers();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleApplyManualCode(CartViewModel cartVM) {
    final code = _codeController.text.trim();
    final err = cartVM.applyVoucherByCode(code);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã áp dụng mã ưu đãi "${code.toUpperCase()}" thành công! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final vouchers = cartVM.vouchers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Ví Voucher Ưu Đãi'),
      ),
      body: Column(
        children: [
          // Ô nhập mã giảm giá thủ công
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã ưu đãi (VD: LOWLANDNEW)',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _handleApplyManualCode(cartVM),
                  child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Danh sách Voucher khả dụng
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => cartVM.loadVouchers(),
              child: vouchers.isEmpty
                  ? const Center(
                      child: Text('Hiện chưa có voucher nào khả dụng.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vouchers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        final isExpired = voucher.isExpired;
                        final isOutOfStock = voucher.isOutOfStock;
                        final isFirstOrderBlocked = voucher.onlyFirstOrder && cartVM.hasPreviousValidOrders;
                        final isAlreadyUsedByUser = voucher.oncePerUser && cartVM.hasUsedVoucherBefore(voucher.code);
                        final isLockedForUser = isExpired || isOutOfStock || isFirstOrderBlocked || isAlreadyUsedByUser;

                        final matchesCat = cartVM.matchesCategoryCondition(voucher);
                        final meetsMinOrder = cartVM.subtotal >= voucher.minOrderValue;
                        final isEligible = !isLockedForUser && matchesCat && meetsMinOrder;
                        final isSelected = !isLockedForUser && cartVM.selectedVoucher?.code == voucher.code;

                        String statusMsg;
                        Color statusColor;
                        String lockedBtnLabel = 'Đã hết hạn';

                        if (isExpired) {
                          statusMsg = 'Thời hạn chương trình đã kết thúc';
                          statusColor = AppColors.error;
                          lockedBtnLabel = 'Đã hết hạn';
                        } else if (isOutOfStock) {
                          statusMsg = 'Mã ưu đãi đã hết lượt sử dụng';
                          statusColor = AppColors.error;
                          lockedBtnLabel = 'Hết lượt';
                        } else if (isFirstOrderBlocked) {
                          statusMsg = 'Chỉ dành cho đơn hàng đầu tiên (Bạn đã đặt đơn trước đó)';
                          statusColor = AppColors.error;
                          lockedBtnLabel = 'Đã qua đơn đầu';
                        } else if (isAlreadyUsedByUser) {
                          statusMsg = 'Bạn đã sử dụng mã ưu đãi này ở đơn trước';
                          statusColor = AppColors.error;
                          lockedBtnLabel = 'Đã sử dụng';
                        } else if (!matchesCat) {
                          statusMsg = 'Giỏ hàng cần có món "${voucher.applicableCategory}"';
                          statusColor = AppColors.accentDark;
                        } else if (!meetsMinOrder) {
                          statusMsg = 'Mua thêm ${CurrencyFormatter.format(voucher.minOrderValue - cartVM.subtotal)} để dùng';
                          statusColor = AppColors.accentDark;
                        } else {
                          statusMsg = 'Đủ điều kiện áp dụng';
                          statusColor = AppColors.success;
                        }

                        return Opacity(
                          opacity: isLockedForUser ? 0.65 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isLockedForUser ? Colors.grey.shade100 : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : (isLockedForUser ? Colors.grey.shade300 : AppColors.border),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isLockedForUser
                                                ? [Colors.grey.shade500, Colors.grey.shade400]
                                                : [AppColors.primary, AppColors.accent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.confirmation_number_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isLockedForUser ? Colors.grey.shade200 : AppColors.surfaceCream,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isLockedForUser
                                                          ? Colors.grey.shade400
                                                          : AppColors.accent.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    voucher.code,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: isLockedForUser ? Colors.grey.shade700 : AppColors.primary,
                                                      letterSpacing: 1.0,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isExpired
                                                        ? AppColors.error.withValues(alpha: 0.12)
                                                        : AppColors.success.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    isExpired ? 'Đã kết thúc' : 'Còn ${voucher.remainingDays} ngày',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isExpired ? AppColors.error : AppColors.success,
                                                    ),
                                                  ),
                                                ),
                                                if (voucher.onlyFirstOrder)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      '🆕 Đơn đầu tiên',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.deepOrange,
                                                      ),
                                                    ),
                                                  )
                                                else if (voucher.oncePerUser)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      '👤 1 lần/khách',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                if (voucher.applicableCategory != 'all' &&
                                                    voucher.applicableCategory.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '🍵 ${voucher.applicableCategory}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              voucher.title,
                                              style: AppTextStyles.subtitle.copyWith(
                                                color: isLockedForUser ? Colors.grey.shade600 : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    voucher.description,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Đơn tối thiểu: ${CurrencyFormatter.format(voucher.minOrderValue)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                          color: isExpired ? AppColors.error : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          statusMsg,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isLockedForUser)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey.shade300,
                                            disabledBackgroundColor: Colors.grey.shade300,
                                            disabledForegroundColor: Colors.grey.shade600,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            minimumSize: const Size(0, 36),
                                            elevation: 0,
                                          ),
                                          onPressed: null,
                                          child: Text(lockedBtnLabel),
                                        )
                                      else if (isSelected)
                                        TextButton.icon(
                                          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                                          label: const Text(
                                            'Đang áp dụng (Bấm hủy)',
                                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          onPressed: () {
                                            cartVM.removeVoucher();
                                          },
                                        )
                                      else
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isEligible ? AppColors.primary : Colors.grey.shade400,
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          onPressed: isEligible
                                              ? () {
                                                  final applied = cartVM.applyVoucher(voucher);
                                                  if (applied) {
                                                    if (Navigator.canPop(context)) {
                                                      Navigator.pop(context);
                                                    }
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Đã áp dụng mã "${voucher.code}"!'),
                                                        backgroundColor: AppColors.success,
                                                      ),
                                                    );
                                                  } else if (cartVM.message != null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(cartVM.message!),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                  }
                                                }
                                              : () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(statusMsg),
                                                      backgroundColor: AppColors.error,
                                                    ),
                                                  );
                                                },
                                          child: Text(isEligible ? 'Dùng ngay' : 'Chưa đủ ĐK'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
