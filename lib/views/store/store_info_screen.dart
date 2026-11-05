import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/store_model.dart';
import '../../data/services/remote/firestore_service.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Thông tin Quán café & Bản đồ tương tác OpenStreetMap (flutter_map)
/// 100% Miễn phí, Không cần API Key, Không cần thẻ tín dụng, Chạy mượt trên cả Android và Web
class StoreInfoScreen extends StatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  late final StoreModel _store;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _store = FirestoreService.instance.getFlagshipStore();
  }

  /// Gọi hotline quán
  Future<void> _callHotline() async {
    final uri = Uri.parse('tel:${_store.hotline.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gọi đến hotline: ${_store.hotline}')),
        );
      }
    }
  }

  /// Mở chỉ đường bằng Google Maps ứng dụng ngoài
  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_store.latitude},${_store.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng chỉ đường.')),
        );
      }
    }
  }

  /// Sao chép mật khẩu Wifi vào bộ nhớ tạm
  void _copyWifiPassword() {
    Clipboard.setData(ClipboardData(text: _store.wifiPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mật khẩu Wifi vào bộ nhớ tạm!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeLocation = ll.LatLng(_store.latitude, _store.longitude);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông tin Quán café'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bản đồ tương tác OpenStreetMap (flutter_map)
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: storeLocation,
                      initialZoom: 16.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // Tile layer OpenStreetMap (Miễn phí 100%)
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.lowland_coffee',
                      ),

                      // Ghim vị trí (Marker) Quán Flagship
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: storeLocation,
                            width: 120,
                            height: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'LOWLAND COFFEE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.redAccent,
                                  size: 34,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Nút căn giữa vị trí quán (Recenter)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      tooltip: 'Định vị lại quán',
                      onPressed: () {
                        _mapController.move(storeLocation, 16.0);
                      },
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),

                  // Nhãn nguồn OpenStreetMap
                  Positioned(
                    left: 8,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 9, color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Nút bấm mở chỉ đường nhanh bằng Google Maps ngoài
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: CustomButton(
                text: 'Chỉ đường đến Quán (Google Maps)',
                icon: Icons.directions_rounded,
                onPressed: _openDirections,
              ),
            ),

            // Chi tiết thông tin quán
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_store.name, style: AppTextStyles.heading2),
                    const SizedBox(height: 16),

                    // Địa chỉ
                    _buildInfoRow(
                      icon: Icons.location_on_rounded,
                      title: 'Địa chỉ Quán',
                      subtitle: _store.address,
                    ),
                    const Divider(height: 24),

                    // Hotline
                    _buildInfoRow(
                      icon: Icons.phone_in_talk_rounded,
                      title: 'Hotline đặt bàn & giao hàng',
                      subtitle: _store.hotline,
                      actionIcon: Icons.phone_forwarded_rounded,
                      onActionTap: _callHotline,
                    ),
                    const Divider(height: 24),

                    // Giờ phục vụ
                    _buildInfoRow(
                      icon: Icons.access_time_filled_rounded,
                      title: 'Giờ phục vụ',
                      subtitle: _store.openingHours,
                    ),
                    const Divider(height: 24),

                    // Thông tin Wifi quán
                    _buildInfoRow(
                      icon: Icons.wifi_rounded,
                      title: 'Wifi miễn phí: ${_store.wifiName}',
                      subtitle: 'Mật khẩu: ${_store.wifiPassword}',
                      actionIcon: Icons.copy_rounded,
                      onActionTap: _copyWifiPassword,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? actionIcon,
    VoidCallback? onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (actionIcon != null)
          IconButton(
            icon: Icon(actionIcon, color: AppColors.accent, size: 22),
            onPressed: onActionTap,
          ),
      ],
    );
  }
}
