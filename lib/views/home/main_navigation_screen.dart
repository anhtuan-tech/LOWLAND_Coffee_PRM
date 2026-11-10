import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/favorite_viewmodel.dart';
import '../../viewmodels/order_history_viewmodel.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';
import '../menu/menu_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';

/// Màn hình điều hướng chính với Bottom Navigation Bar (5 tab: Thực đơn, Yêu thích, Giỏ hàng, Đơn hàng, Tài khoản)
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    MenuScreen(),
    FavoritesScreen(),
    CartScreen(),
    OrderHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            context.read<FavoriteViewModel>().loadFavorites();
          } else if (index == 2) {
            context.read<CartViewModel>().loadCart();
          } else if (index == 3) {
            final currentUid = context.read<AuthViewModel>().currentUser?.uid;
            context.read<OrderHistoryViewModel>().loadOrders(userId: currentUid);
          }
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.coffee_rounded),
            label: 'Thực đơn',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_rounded),
                if (cartVM.totalItemCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        cartVM.totalItemCount > 9 ? '9+' : '${cartVM.totalItemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Giỏ hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Đơn hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
