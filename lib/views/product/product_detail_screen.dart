import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/favorite_viewmodel.dart';
import '../../viewmodels/product_detail_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Chi tiết sản phẩm & Tùy chọn (Customization: Size, Đường, Đá, Topping)
class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailViewModel(product: product),
      child: const _ProductDetailContent(),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductDetailViewModel>();
    final product = vm.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar dạng Sliver với ảnh lớn
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: Icon(
                    vm.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: vm.isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () async {
                    if (!AuthGuard.checkAuth(context, actionMessage: 'lưu món vào danh sách yêu thích')) {
                      return;
                    }
                    await vm.toggleFavorite();
                    if (context.mounted) {
                      context.read<FavoriteViewModel>().loadFavorites();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            vm.isFavorite
                                ? 'Đã thêm "${product.name}" vào danh sách yêu thích ❤️'
                                : 'Đã bỏ yêu thích món "${product.name}"',
                          ),
                          backgroundColor: vm.isFavorite ? AppColors.accent : AppColors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceCream,
                      child: const Icon(Icons.coffee_rounded, size: 80, color: AppColors.primary),
                    ),
                  ),
                  // Gradient che mờ
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent, Colors.black45],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung chi tiết & các tùy chọn
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên món & Giá cơ bản
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTextStyles.heading2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: AppTextStyles.priceLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mô tả sản phẩm
                  Text(
                    product.description,
                    style: AppTextStyles.body,
                  ),
                  const Divider(height: 32),

                  // 1. Tùy chọn Kích cỡ (Size S/M/L)
                  if (product.availableSizes.isNotEmpty) ...[
                    _buildSectionHeader('1. Chọn Kích cỡ (Size)', 'Bắt buộc'),
                    const SizedBox(height: 12),
                    Row(
                      children: product.availableSizes.map((size) {
                        final isSelected = vm.selectedSize == size;
                        String priceLabel = '';
                        if (size == 'M') priceLabel = '(+6.000đ)';
                        if (size == 'L') priceLabel = '(+10.000đ)';

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Size $size\n$priceLabel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.2,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => vm.setSize(size),
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceCream,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                  ],

                  // 2. Tùy chọn Mức đường
                  if (product.category != 'Bánh') ...[
                    _buildSectionHeader('2. Mức đường', '${vm.selectedSugar}%'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [0, 30, 50, 70, 100].map((sugar) {
                        final isSelected = vm.selectedSugar == sugar;
                        return ChoiceChip(
                          label: Text('$sugar%'),
                          selected: isSelected,
                          onSelected: (_) => vm.setSugar(sugar),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceCream,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),

                    // 3. Tùy chọn Mức đá
                    _buildSectionHeader('3. Mức đá', '${vm.selectedIce}%'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [0, 30, 50, 70, 100].map((ice) {
                        final isSelected = vm.selectedIce == ice;
                        return ChoiceChip(
                          label: Text('$ice%'),
                          selected: isSelected,
                          onSelected: (_) => vm.setIce(ice),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceCream,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.textLight : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                  ],

                  // 4. Chọn Topping đi kèm
                  if (product.availableToppings.isNotEmpty) ...[
                    _buildSectionHeader('4. Chọn Topping', 'Tùy chọn'),
                    const SizedBox(height: 8),
                    ...product.availableToppings.map((topping) {
                      final isChecked = vm.selectedToppings.contains(topping);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(
                          topping,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        value: isChecked,
                        onChanged: (_) => vm.toggleTopping(topping),
                      );
                    }),
                    const Divider(height: 24),
                  ],

                  // Số lượng (+/-)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số lượng:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: vm.decreaseQuantity,
                              color: AppColors.primary,
                            ),
                            Text(
                              '${vm.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: vm.increaseQuantity,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80), // Padding cho nút đáy
                ],
              ),
            ),
          ),
        ],
      ),

      // Thanh đáy chứa Nút thêm vào giỏ hàng
      bottomNavigationBar: Container(
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
            text: 'Thêm vào giỏ • ${CurrencyFormatter.format(vm.totalPrice)}',
            isLoading: vm.isAddingToCart,
            icon: Icons.add_shopping_cart_rounded,
            onPressed: () async {
              if (!AuthGuard.checkAuth(context, actionMessage: 'thêm món vào giỏ hàng')) {
                return;
              }
              final success = await vm.addToCart();
              if (success && context.mounted) {
                // Tải lại giỏ hàng trong CartViewModel
                context.read<CartViewModel>().loadCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'Xem giỏ',
                      textColor: Colors.white,
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.subtitle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.accentDark,
            ),
          ),
        ),
      ],
    );
  }
}

