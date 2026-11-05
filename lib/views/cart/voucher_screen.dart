import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/voucher_model.dart';
import '../../viewmodels/cart_viewmodel.dart';

/// Màn hình Danh sách Mã giảm giá (Vouchers) LOWLAND Coffee
class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final vouchers = cartVM.vouchers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Mã giảm giá LOWLAND'),
      ),
      body: vouchers.isEmpty
          ? const Center(
              child: Text('Hiện chưa có voucher nào khả dụng.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                final isSelected = cartVM.selectedVoucher?.code == voucher.code;
                final isEligible = cartVM.subtotal >= voucher.minOrderValue;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCream,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.confirmation_number_rounded,
                                color: AppColors.accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voucher.code,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    voucher.title,
                                    style: AppTextStyles.subtitle,
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
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isSelected)
                              TextButton.icon(
                                icon: const Icon(Icons.check, color: AppColors.success, size: 18),
                                label: const Text('Đang áp dụng', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
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
                                        }
                                      }
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Cần mua thêm món để đạt đơn tối thiểu ${CurrencyFormatter.format(voucher.minOrderValue)}',
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(isEligible ? 'Áp dụng' : 'Chưa đủ điều kiện'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

